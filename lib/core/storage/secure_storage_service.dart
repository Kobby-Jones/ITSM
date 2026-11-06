// ignore_for_file: deprecated_member_use, unnecessary_import

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Wraps [FlutterSecureStorage] for sensitive authentication state.
///
/// Besides JWTs, the service keeps:
/// - a small encrypted snapshot of the last server-verified user profile, and
/// - a salted PBKDF2-style password verifier for that same account.
///
/// The verifier allows the *previously verified account on this device* to
/// authenticate while the backend is unreachable. The user's actual password
/// is never stored.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';
  static const _kOfflineUserProfile = 'auth_offline_user_profile';
  static const _kOfflineAuthenticatedAt = 'auth_offline_authenticated_at';
  static const _kOfflineEmail = 'auth_offline_email';
  static const _kOfflinePasswordSalt = 'auth_offline_password_salt';
  static const _kOfflinePasswordVerifier = 'auth_offline_password_verifier';
  static const _kOfflinePasswordIterations = 'auth_offline_password_iterations';
  static const _kTelemetryDeviceId = 'telemetry_device_id';

  /// How long a previously server-verified account may be used offline.
  /// Successful online login or /auth/me refreshes this timestamp.
  static const Duration offlineSessionValidity = Duration(hours: 72);

  /// Deliberately expensive enough to make a stolen verifier less useful,
  /// while remaining practical on a phone. The derivation is run in a worker
  /// isolate where supported so it does not block the login UI.
  static const int _offlineVerifierIterations = 50000;

  String? _accessTokenCache;
  String? _refreshTokenCache;
  String? _userIdCache;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
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

  /// Stores the last user profile that the backend successfully verified.
  Future<void> saveOfflineUserProfile(Map<String, dynamic> userJson) async {
    await _storage.write(
      key: _kOfflineUserProfile,
      value: jsonEncode(userJson),
    );
    await _storage.write(
      key: _kOfflineAuthenticatedAt,
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Saves a local password verifier after a successful *online* login.
  ///
  /// The password itself is never written to storage. A fresh random salt is
  /// generated each time an online login succeeds.
  Future<void> saveOfflineLoginCredential({
    required String email,
    required String password,
  }) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );

    final verifier = await compute(
      _deriveOfflineVerifier,
      <String, Object>{
        'password': password,
        'salt': base64Encode(salt),
        'iterations': _offlineVerifierIterations,
      },
    );

    await _storage.write(
      key: _kOfflineEmail,
      value: email.trim().toLowerCase(),
    );
    await _storage.write(
      key: _kOfflinePasswordSalt,
      value: base64Encode(salt),
    );
    await _storage.write(
      key: _kOfflinePasswordVerifier,
      value: verifier,
    );
    await _storage.write(
      key: _kOfflinePasswordIterations,
      value: _offlineVerifierIterations.toString(),
    );
  }

  /// Checks the credentials against the verifier created by the last
  /// successful online login. Returns false for another user, expired/corrupt
  /// verifier data, or an incorrect password.
  Future<bool> verifyOfflineLoginCredential({
    required String email,
    required String password,
  }) async {
    if (!await hasValidOfflineProfile) return false;

    final storedEmail = await _storage.read(key: _kOfflineEmail);
    final salt = await _storage.read(key: _kOfflinePasswordSalt);
    final expected = await _storage.read(key: _kOfflinePasswordVerifier);
    final rawIterations =
        await _storage.read(key: _kOfflinePasswordIterations);

    if (storedEmail == null ||
        salt == null ||
        expected == null ||
        rawIterations == null) {
      return false;
    }

    if (storedEmail != email.trim().toLowerCase()) return false;

    final iterations = int.tryParse(rawIterations);
    if (iterations == null || iterations <= 0) return false;

    try {
      final actual = await compute(
        _deriveOfflineVerifier,
        <String, Object>{
          'password': password,
          'salt': salt,
          'iterations': iterations,
        },
      );
      return _constantTimeEquals(expected, actual);
    } catch (_) {
      return false;
    }
  }

  /// Returns the encrypted cached profile only while it is within the
  /// configured offline-session validity window.
  Future<Map<String, dynamic>?> getValidOfflineUserProfile() async {
    final rawProfile = await _storage.read(key: _kOfflineUserProfile);
    final rawAuthenticatedAt =
        await _storage.read(key: _kOfflineAuthenticatedAt);

    if (rawProfile == null || rawAuthenticatedAt == null) return null;

    final authenticatedAt = DateTime.tryParse(rawAuthenticatedAt)?.toUtc();
    if (authenticatedAt == null) return null;

    final age = DateTime.now().toUtc().difference(authenticatedAt);
    if (age.isNegative || age > offlineSessionValidity) return null;

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Corrupt/legacy cached data should never prevent normal online login.
    }
    return null;
  }

  Future<bool> get hasValidOfflineProfile async =>
      await getValidOfflineUserProfile() != null;

  /// Clears bearer/refresh state while deliberately preserving the last
  /// verified offline profile and password verifier. This is used for a local
  /// logout so the same user can explicitly sign back in while offline.
  Future<void> clearSessionTokens() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    _userIdCache = null;

    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
  }

  /// Completely forgets the device's authentication state, including offline
  /// credentials. Use when the server definitively forbids the account or
  /// when a future "forget this device" action is requested.
  Future<void> clear() async {
    await clearSessionTokens();
    await _storage.delete(key: _kOfflineUserProfile);
    await _storage.delete(key: _kOfflineAuthenticatedAt);
    await _storage.delete(key: _kOfflineEmail);
    await _storage.delete(key: _kOfflinePasswordSalt);
    await _storage.delete(key: _kOfflinePasswordVerifier);
    await _storage.delete(key: _kOfflinePasswordIterations);
  }


  /// Returns a stable installation/device identifier for telemetry.
  ///
  /// The identifier is generated once and deliberately survives auth logout
  /// so telemetry from the same installation can be correlated over time.
  Future<String> getOrCreateTelemetryDeviceId() async {
    final existing = await _storage.read(key: _kTelemetryDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = const Uuid().v4();
    await _storage.write(key: _kTelemetryDeviceId, value: created);
    return created;
  }

  Future<bool> get hasSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }
}

/// Worker-friendly PBKDF2-HMAC-SHA256 derivation. Only one 32-byte block is
/// needed because SHA-256 output is already 32 bytes.
String _deriveOfflineVerifier(Map<String, Object> args) {
  final password = args['password']! as String;
  final salt = base64Decode(args['salt']! as String);
  final iterations = args['iterations']! as int;

  final mac = Hmac(sha256, utf8.encode(password));
  final firstInput = Uint8List(salt.length + 4)
    ..setRange(0, salt.length, salt)
    ..setRange(salt.length, salt.length + 4, const [0, 0, 0, 1]);

  var u = Uint8List.fromList(mac.convert(firstInput).bytes);
  final result = Uint8List.fromList(u);

  for (var i = 1; i < iterations; i++) {
    u = Uint8List.fromList(mac.convert(u).bytes);
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }

  return base64Encode(result);
}

bool _constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  if (left.length != right.length) return false;

  var diff = 0;
  for (var i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff == 0;
}
