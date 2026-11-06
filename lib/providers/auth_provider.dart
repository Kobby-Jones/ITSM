import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_cache_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/storage/sync_queue_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

@immutable
class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  /// True while `AuthController` is checking for a stored session on app
  /// start. The router shows the splash screen until this settles.
  final bool restoring;

  /// True when the user was restored from the last server-verified encrypted
  /// profile because the backend could not currently be reached.
  final bool offlineSession;

  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.restoring = true,
    this.offlineSession = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
    bool? restoring,
    bool? offlineSession,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      restoring: restoring ?? this.restoring,
      offlineSession: offlineSession ?? this.offlineSession,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  /// Kept only in memory after an explicit offline credential login. It is
  /// never persisted. If connectivity returns during the same app session,
  /// it can be used to obtain fresh server tokens automatically when the
  /// local logout path had previously removed them.
  String? _offlinePasswordForReauth;

  AuthController() : super(const AuthState()) {
    // ApiClient only invokes this callback after a refresh token is
    // definitively rejected. Network failures do not call it.
    ApiClient.instance.onSessionExpired = () {
      SyncQueueService.instance.clearCurrentUser();
      state = const AuthState(restoring: false);
    };
    _restoreSession();
  }

  /// Restores a previous session at startup.
  ///
  /// Online path: validate the stored token with `GET /auth/me` and refresh
  /// the encrypted offline profile.
  ///
  /// Offline/backend-unavailable path: if the tokens are still present and
  /// the last successful server verification is no older than 72 hours,
  /// restore that encrypted profile instead of logging the user out.
  Future<void> _restoreSession() async {
    final storage = SecureStorageService.instance;
    final hadSession = await storage.hasSession;
    if (!hadSession) {
      state = state.copyWith(restoring: false);
      return;
    }

    try {
      final user = await AuthService.instance.fetchMe();
      LocalCacheService.instance.setCurrentUser(user.id);
      SyncQueueService.instance.setCurrentUser(user.id);
      state = AuthState(
        user: user,
        restoring: false,
        offlineSession: false,
      );
    } on ApiException catch (e) {
      final sessionStillPresent = await storage.hasSession;

      if (sessionStillPresent && _canFallbackOffline(e)) {
        final cached = await storage.getValidOfflineUserProfile();
        if (cached != null) {
          try {
            final user = AppUser.fromJson(cached);
            LocalCacheService.instance.setCurrentUser(user.id);
            SyncQueueService.instance.setCurrentUser(user.id);
            state = AuthState(
              user: user,
              restoring: false,
              offlineSession: true,
            );
            return;
          } catch (_) {
            // Fall through to the unauthenticated state if cached profile
            // shape is incompatible/corrupt.
          }
        }
      }

      // If refresh was definitively rejected ApiClient already cleared the
      // tokens. Forbidden responses are also not safe to bypass offline.
      // For a transient outage with an expired offline window, preserve the
      // tokens so a later online app start can validate them again.
      if (!sessionStillPresent || e is ForbiddenException) {
        await storage.clear();
      }
      state = const AuthState(restoring: false);
    } catch (_) {
      // Unknown failures are not proof the credentials are invalid. Try the
      // encrypted last-known verified profile before giving up.
      final sessionStillPresent = await storage.hasSession;
      if (sessionStillPresent) {
        final cached = await storage.getValidOfflineUserProfile();
        if (cached != null) {
          try {
            final user = AppUser.fromJson(cached);
            LocalCacheService.instance.setCurrentUser(user.id);
            SyncQueueService.instance.setCurrentUser(user.id);
            state = AuthState(
              user: user,
              restoring: false,
              offlineSession: true,
            );
            return;
          } catch (_) {
            // Ignore corrupt cache and show login.
          }
        }
      }
      state = const AuthState(restoring: false);
    }
  }

  bool _canFallbackOffline(ApiException error) {
    return error is NetworkException ||
        error is ServerException ||
        error is RateLimitException ||
        error is UnauthorizedException;
  }

  /// Attempts to turn an offline-restored session back into a fully
  /// server-verified session. Safe to call from the offline banner when
  /// connectivity/server access returns.
  Future<void> revalidateSession() async {
    if (!state.isAuthenticated || !state.offlineSession) return;

    final storage = SecureStorageService.instance;
    try {
      AppUser user;

      if (await storage.hasSession) {
        // Normal case: the app went offline while already signed in, so the
        // stored access/refresh credentials can simply be validated/refreshed.
        user = await AuthService.instance.fetchMe();
      } else if (_offlinePasswordForReauth != null && state.user != null) {
        // Explicit offline credential login after a local logout has no JWTs.
        // Use the password held only in memory to obtain fresh tokens when
        // the server becomes reachable again.
        user = await AuthService.instance.login(
          state.user!.email,
          _offlinePasswordForReauth!,
        );
      } else {
        // The app was restarted after an offline credential login with no
        // server tokens. Keep the local session; the user can sign in again
        // once online to obtain fresh server credentials.
        return;
      }

      _offlinePasswordForReauth = null;
      LocalCacheService.instance.setCurrentUser(user.id);
      SyncQueueService.instance.setCurrentUser(user.id);
      state = AuthState(
        user: user,
        restoring: false,
        offlineSession: false,
      );
    } on ApiException catch (e) {
      final sessionStillPresent = await storage.hasSession;
      if (e is ForbiddenException || e is UnauthorizedException) {
        _offlinePasswordForReauth = null;
        await storage.clear();
        state = const AuthState(restoring: false);
        return;
      }
      if (!sessionStillPresent && _offlinePasswordForReauth == null) {
        // No server credential exists to revalidate right now. Preserve the
        // local offline session rather than throwing the user out.
        return;
      }
      // Transient network/server/rate-limit failures keep the working
      // offline session in place.
    }
  }

  Future<void> login(String email, String password) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);

    try {
      final user = await AuthService.instance.login(email, password);
      _offlinePasswordForReauth = null;
      LocalCacheService.instance.setCurrentUser(user.id);
      SyncQueueService.instance.setCurrentUser(user.id);
      state = AuthState(
        user: user,
        restoring: false,
        offlineSession: false,
      );
      return;
    } on ApiException catch (e) {
      // Never bypass a definite credential/permission rejection from the
      // server. Offline credential login is only a fallback for temporary
      // unavailability such as no data, DNS failure, 5xx or rate limiting.
      if (_canUseCredentialOffline(e)) {
        try {
          final offlineUser =
              await AuthService.instance.tryOfflineLogin(email, password);
          if (offlineUser != null) {
            _offlinePasswordForReauth = password;
            LocalCacheService.instance.setCurrentUser(offlineUser.id);
            SyncQueueService.instance.setCurrentUser(offlineUser.id);
            state = AuthState(
              user: offlineUser,
              restoring: false,
              offlineSession: true,
            );
            return;
          }
        } catch (_) {
          // Fall through to the useful offline-login error below.
        }

        state = state.copyWith(
          loading: false,
          error:
              'Offline sign-in is unavailable for these credentials. Connect to the internet and sign in successfully once on this device, then offline sign-in will be available for up to 72 hours.',
        );
        return;
      }

      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      // An unexpected transport/runtime failure may still be recoverable from
      // the locally verified credential.
      try {
        final offlineUser =
            await AuthService.instance.tryOfflineLogin(email, password);
        if (offlineUser != null) {
          _offlinePasswordForReauth = password;
          LocalCacheService.instance.setCurrentUser(offlineUser.id);
          SyncQueueService.instance.setCurrentUser(offlineUser.id);
          state = AuthState(
            user: offlineUser,
            restoring: false,
            offlineSession: true,
          );
          return;
        }
      } catch (_) {}

      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  bool _canUseCredentialOffline(ApiException error) {
    return error is NetworkException ||
        error is ServerException ||
        error is RateLimitException;
  }

  /// NOTE: `department` is collected by the register screen as free text
  /// but the backend's `POST /auth/register` only accepts a `departmentId`
  /// (a real department record), so it isn't sent yet — new accounts land
  /// with no department assigned until an admin sets one via user
  /// management. Wiring a department picker backed by a real
  /// `GET /departments` endpoint would close this gap.
  Future<void> register({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : name;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      await AuthService.instance.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      // Registration creates an ACTIVE account — log in immediately.
      final user = await AuthService.instance.login(email, password);
      LocalCacheService.instance.setCurrentUser(user.id);
      SyncQueueService.instance.setCurrentUser(user.id);
      state = AuthState(
        user: user,
        restoring: false,
        offlineSession: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await AuthService.instance.forgotPassword(email);
      state = state.copyWith(loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> logout() async {
    // End the active session but keep the server-verified offline credential
    // on this device. The same user must still enter the correct password to
    // sign back in offline; the password itself is never stored.
    _offlinePasswordForReauth = null;
    await LocalCacheService.instance.clearCurrentUser();
    SyncQueueService.instance.clearCurrentUser();
    await AuthService.instance.logout();
    state = const AuthState(restoring: false);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
