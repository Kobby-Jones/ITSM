import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// Thin, shared Dio instance used by every `*_service.dart`.
///
/// Responsibilities:
/// - Attaches `Authorization: Bearer <token>` to every request.
/// - On a 401, attempts one single-flight refresh and retries the original
///   request once.
/// - Only expires the local session when the refresh credential itself is
///   definitively rejected. Network errors and temporary server failures do
///   not erase a valid local session.
/// - Converts Dio/network errors into typed [ApiException] instances.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.instance.accessToken;
          final hasToken = token != null && token.isNotEmpty;
          if (hasToken) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode && !options.path.contains('/auth/login')) {
            debugPrint(
              '[AUTH] ${hasToken ? 'Bearer token attached' : 'MISSING bearer token'} '
              'for ${options.method} ${options.path}',
            );
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final response = error.response;

          if (response?.statusCode == 401 && _shouldAttemptRefresh(error)) {
            if (kDebugMode) {
              final message = _responseMessage(response?.data);
              debugPrint(
                '[AUTH] 401 on ${error.requestOptions.method} '
                '${error.requestOptions.path}: $message',
              );
            }

            try {
              final retried = await _refreshAndRetry(error);
              return handler.resolve(retried);
            } on _RefreshRejectedException catch (refreshError) {
              if (kDebugMode) {
                debugPrint('[AUTH] Session expired: ${refreshError.message}');
              }
              await _expireSession();
            } catch (refreshError) {
              // A timeout, DNS error, 5xx response, malformed response, etc.
              // is not proof that the refresh token is invalid. Preserve the
              // local session and surface the original request failure.
              if (kDebugMode) {
                debugPrint(
                  '[AUTH] Token refresh could not complete; session preserved. '
                  'Error: $refreshError',
                );
              }
            }
          }

          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        // Never print request headers or request bodies here: auth headers
        // contain bearer tokens and /auth/login contains the user's password.
        // The safe [AUTH] diagnostics above report only whether a token was
        // attached; they never print credentials.
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          error: true,
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Set by AuthController so a definitively rejected refresh token can move
  /// the application back to the unauthenticated state.
  VoidCallback? onSessionExpired;

  Future<void>? _refreshing;

  bool _shouldAttemptRefresh(DioException error) {
    final path = error.requestOptions.path;

    // Never refresh recursively for auth endpoints, and never refresh an
    // original request more than once.
    return !path.contains('/auth/login') &&
        !path.contains('/auth/refresh-token') &&
        error.requestOptions.extra['authRetried'] != true;
  }

  Future<Response<dynamic>> _refreshAndRetry(DioException error) async {
    await _ensureSingleRefresh();

    final token = await SecureStorageService.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const _RefreshRejectedException('No access token after refresh');
    }

    final opts = error.requestOptions;
    opts.extra['authRetried'] = true;
    opts.headers['Authorization'] = 'Bearer $token';

    return _dio.fetch<dynamic>(opts);
  }

  Future<void> _ensureSingleRefresh() async {
    final inFlight = _refreshing;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final refreshFuture = _doRefresh();
    _refreshing = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      if (identical(_refreshing, refreshFuture)) {
        _refreshing = null;
      }
    }
  }

  Future<void> _doRefresh() async {
    final refreshToken = await SecureStorageService.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const _RefreshRejectedException('No refresh token is stored');
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    Response<dynamic> response;
    try {
      response = await refreshDio.post<dynamic>(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        throw _RefreshRejectedException(
          _responseMessage(e.response?.data),
        );
      }
      rethrow;
    }

    final root = response.data;
    if (root is! Map || root['data'] is! Map) {
      throw const FormatException('Unexpected refresh response');
    }

    final data = Map<String, dynamic>.from(root['data'] as Map);
    final accessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        newRefreshToken is! String ||
        newRefreshToken.isEmpty) {
      throw const FormatException('Refresh response did not contain tokens');
    }

    await SecureStorageService.instance.saveTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );

    debugAccessTokenLifetime(accessToken, source: 'refresh');
  }

  Future<void> _expireSession() async {
    await SecureStorageService.instance.clear();
    onSessionExpired?.call();
  }

  static String _responseMessage(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return 'Unauthorized';
  }

  /// Debug-only token lifetime logging. It never prints the token itself.
  /// This makes an accidentally misconfigured production expiry such as
  /// `JWT_ACCESS_EXPIRES_IN=15` (milliseconds in jsonwebtoken when supplied
  /// as a string) immediately visible in the Flutter terminal.
  static void debugAccessTokenLifetime(String token, {required String source}) {
    if (!kDebugMode) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('[AUTH] $source access token is not a JWT');
        return;
      }

      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map) return;

      final iat = payload['iat'];
      final exp = payload['exp'];
      if (iat is num && exp is num) {
        final lifetimeSeconds = exp.toInt() - iat.toInt();
        final remainingSeconds =
            exp.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
        debugPrint(
          '[AUTH] $source access-token lifetime=${lifetimeSeconds}s, '
          'remaining=${remainingSeconds}s',
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Could not inspect access-token expiry: $e');
    }
  }

  /// Converts any thrown error from a `dio.get/post/...` call into an
  /// [ApiException].
  ApiException mapError(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) return ServerException(error.toString());

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    final message = (body is Map && body['message'] is String)
        ? body['message'] as String
        : error.message ?? 'Request failed';

    switch (status) {
      case 400:
      case 422:
        final rawErrors = (body is Map ? body['errors'] : null) as List?;
        return ValidationException(
          message,
          errors: rawErrors
                  ?.map((e) => Map<String, String?>.from(
                      (e as Map).map(
                        (k, v) => MapEntry(k.toString(), v?.toString()),
                      ),
                    ))
                  .toList() ??
              const [],
        );
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 429:
        return const RateLimitException();
      default:
        return ServerException(message, status);
    }
  }
}

class _RefreshRejectedException implements Exception {
  final String message;
  const _RefreshRejectedException(this.message);

  @override
  String toString() => message;
}
