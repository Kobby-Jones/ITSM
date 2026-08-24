// ignore_for_file: deprecated_member_use

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for the handful of sensitive values we need
/// to persist: JWT access/refresh tokens and the last-known user id.
///
/// Tokens are also cached in memory for the lifetime of the process. This is
/// especially useful on desktop because every API request should not need to
/// perform a native credential-store read just to attach the bearer token.
/// Persistent secure storage remains the source used after an app restart.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';

  String? _accessTokenCache;
  String? _refreshTokenCache;
  String? _userIdCache;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Write sequentially. The native credential-store plugins are already
    // fast and sequential writes avoid unnecessary concurrent access to the
    // same secure-storage backend on desktop platforms.
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);

    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
  }

  Future<String?> get accessToken async {
    if (_accessTokenCache != null) return _accessTokenCache;
    _accessTokenCache = await _storage.read(key: _kAccessToken);
    return _accessTokenCache;
  }

  Future<String?> get refreshToken async {
    if (_refreshTokenCache != null) return _refreshTokenCache;
    _refreshTokenCache = await _storage.read(key: _kRefreshToken);
    return _refreshTokenCache;
  }

  Future<void> saveUserId(String id) async {
    await _storage.write(key: _kUserId, value: id);
    _userIdCache = id;
  }

  Future<String?> get userId async {
    if (_userIdCache != null) return _userIdCache;
    _userIdCache = await _storage.read(key: _kUserId);
    return _userIdCache;
  }

  Future<void> clear() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    _userIdCache = null;

    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
  }

  Future<bool> get hasSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    return access != null && refresh != null;
  }
}
