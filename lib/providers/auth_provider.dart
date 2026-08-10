import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

@immutable
class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;
  /// True while `AuthController` is checking for a stored session on app
  /// start (calling `GET /auth/me`). The router shows the splash screen
  /// until this settles, so we don't flash the login screen for someone
  /// who's already signed in.
  final bool restoring;

  const AuthState({this.user, this.loading = false, this.error, this.restoring = true});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
    bool? restoring,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      restoring: restoring ?? this.restoring,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {

  static const List<({String email, String password, String role, String name})> demoAccounts = [
    (email: 'superadmin@itsm.com', password: 'SuperAdmin@2024!', role: 'Super Admin', name: 'Super Admin'),
    (email: 'technician@itsm.com', password: 'Technician@2024!', role: 'IT Technician', name: 'John Doe'),
    (email: 'user@itsm.com', password: 'EndUser@2024!', role: 'End User', name: 'Jane Smith'),
  ];
  AuthController() : super(const AuthState()) {
    // Wire ApiClient's "refresh failed" callback to force a logout so the
    // router redirects to /login instead of leaving stale UI on screen.
    ApiClient.instance.onSessionExpired = () {
      state = const AuthState(restoring: false);
    };
    _restoreSession();
  }

  /// Called once at startup: if a token is already stored (previous
  /// session), fetch the current user so we land straight on the home
  /// screen instead of login. If the token's invalid/expired, ApiClient's
  /// interceptor will have already cleared storage by the time this throws.
  Future<void> _restoreSession() async {
    final hasSession = await SecureStorageService.instance.hasSession;
    if (!hasSession) {
      state = state.copyWith(restoring: false);
      return;
    }
    try {
      final user = await AuthService.instance.fetchMe();
      state = AuthState(user: user, restoring: false);
    } catch (_) {
      await SecureStorageService.instance.clear();
      state = const AuthState(restoring: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await AuthService.instance.login(email, password);
      state = AuthState(user: user, restoring: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Something went wrong. Please try again.');
    }
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
      // Registration succeeds but the account needs email verification
      // before it can log in (see backend PENDING_VERIFICATION status) —
      // surface that instead of pretending we're now authenticated.
      state = state.copyWith(
        loading: false,
        error: 'Account created! Check your email to verify it, then sign in.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Something went wrong. Please try again.');
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
    await AuthService.instance.logout();
    state = const AuthState(restoring: false);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
