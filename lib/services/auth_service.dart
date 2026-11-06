import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

/// Talks to `/auth/*`. This is the only place that knows about the raw HTTP
/// shape for authentication — `AuthProvider` should only ever call these
/// methods and work with [AppUser] / plain booleans.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _dio = ApiClient.instance.dio;

  Future<AppUser> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final res = await _dio.post(ApiEndpoints.login, data: {
        'email': normalizedEmail,
        'password': password,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      await SecureStorageService.instance.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      ApiClient.debugAccessTokenLifetime(accessToken, source: 'login');

      final userJson = Map<String, dynamic>.from(
        data['user'] as Map,
      );
      await _persistVerifiedUser(userJson);

      // Only a server-approved online login may create/update the local
      // offline password verifier. Failure to persist the verifier must not
      // turn an otherwise successful online login into a login failure.
      try {
        await SecureStorageService.instance.saveOfflineLoginCredential(
          email: normalizedEmail,
          password: password,
        );
      } catch (_) {
        // Online authentication remains usable; the next successful login
        // will retry provisioning offline credential login.
      }

      return AppUser.fromJson(userJson);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Authenticates against the last server-verified account entirely on the
  /// device. This only succeeds for the same email/password previously
  /// accepted online and only while the offline verification window is valid.
  Future<AppUser?> tryOfflineLogin(String email, String password) async {
    final storage = SecureStorageService.instance;
    final verified = await storage.verifyOfflineLoginCredential(
      email: email,
      password: password,
    );
    if (!verified) return null;

    final userJson = await storage.getValidOfflineUserProfile();
    if (userJson == null) return null;

    try {
      return AppUser.fromJson(userJson);
    } catch (_) {
      return null;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      await _dio.post(ApiEndpoints.register, data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Fetches the current user — call on app start when a token is already
  /// stored, to restore the session and get fresh profile data.
  Future<AppUser> fetchMe() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      final userJson = Map<String, dynamic>.from(
        res.data['data'] as Map,
      );
      await _persistVerifiedUser(userJson);
      return AppUser.fromJson(userJson);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> _persistVerifiedUser(Map<String, dynamic> userJson) async {
    final id = userJson['id'];
    if (id is String && id.isNotEmpty) {
      await SecureStorageService.instance.saveUserId(id);
    }
    await SecureStorageService.instance.saveOfflineUserProfile(userJson);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort — local logout still succeeds while offline.
    } finally {
      // Preserve the last server-verified offline credential/profile. This
      // lets the same user explicitly sign back in while there is no network.
      await SecureStorageService.instance.clearSessionTokens();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      // Keep offline authentication aligned with a successfully changed
      // server password when the cached profile contains the user's email.
      final profile =
          await SecureStorageService.instance.getValidOfflineUserProfile();
      final email = profile?['email'];
      if (email is String && email.isNotEmpty) {
        await SecureStorageService.instance.saveOfflineLoginCredential(
          email: email,
          password: newPassword,
        );
      }
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
