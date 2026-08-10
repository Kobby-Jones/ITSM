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
      final res = await _dio.post(ApiEndpoints.login, data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      await SecureStorageService.instance.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      final userJson = data['user'] as Map<String, dynamic>;
      await SecureStorageService.instance.saveUserId(userJson['id'] as String);
      return AppUser.fromJson(userJson);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
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
      return AppUser.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort — clear local session regardless of server response.
    } finally {
      await SecureStorageService.instance.clear();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email.trim().toLowerCase()});
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _dio.post(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
