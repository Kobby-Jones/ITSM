// ignore_for_file: deprecated_member_use

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for the handful of sensitive values we need
/// to persist: JWT access/refresh tokens and the last-known user id.
///
/// Backed by Keychain on iOS/macOS, Keystore-backed EncryptedSharedPreferences
/// on Android, libsecret on Linux, Credential Manager on Windows, and
/// browser-storage-with-a-warning on web (flutter_secure_storage documents
/// this; avoid storing anything beyond short-lived tokens on web builds).
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);

  Future<void> saveUserId(String id) => _storage.write(key: _kUserId, value: id);
  Future<String?> get userId => _storage.read(key: _kUserId);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserId),
    ]);
  }

  Future<bool> get hasSession async => (await accessToken) != null;
}
