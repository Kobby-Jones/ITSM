import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// Thin, shared Dio instance used by every `*_service.dart`.
///
/// Responsibilities:
/// - Attaches `Authorization: Bearer <token>` to every request.
/// - On a 401, attempts a single-flight refresh (concurrent 401s all wait on
///   the same refresh call instead of firing N refresh requests) and retries
///   the original request once. If refresh itself fails, clears the session
///   and notifies [onSessionExpired] so the app can route to /login.
/// - Converts Dio/network errors into the typed [ApiException] hierarchy so
///   calling code never has to touch DioException directly.
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
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final response = error.response;
          if (response?.statusCode == 401 && _shouldAttemptRefresh(error)) {
            try {
              final retried = await _refreshAndRetry(error);
              return handler.resolve(retried);
            } catch (_) {
              await SecureStorageService.instance.clear();
              onSessionExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false, error: true),
      );
    }
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Set by the app's root widget so 401-after-refresh-failure can trigger a
  /// redirect to the login screen without ApiClient depending on GoRouter.
  VoidCallback? onSessionExpired;

  Future<void>? _refreshing;

  bool _shouldAttemptRefresh(DioException error) {
    // Don't try to refresh when the 401 came from the auth endpoints
    // themselves (login/refresh) — that would loop forever.
    final path = error.requestOptions.path;
    return !path.contains('/auth/login') && !path.contains('/auth/refresh-token');
  }

  Future<Response> _refreshAndRetry(DioException error) async {
    // Single-flight: if a refresh is already in progress, wait for it instead
    // of firing another /auth/refresh call.
    _refreshing ??= _doRefresh();
    await _refreshing;
    _refreshing = null;

    final token = await SecureStorageService.instance.accessToken;
    final opts = error.requestOptions;
    opts.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch(opts);
  }

  Future<void> _doRefresh() async {
    final refreshToken = await SecureStorageService.instance.refreshToken;
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await Dio(BaseOptions(baseUrl: Env.baseUrl)).post(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    await SecureStorageService.instance.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  /// Converts any thrown error from a `dio.get/post/...` call into an
  /// [ApiException]. Wrap service calls like:
  /// ```dart
  /// try {
  ///   final res = await ApiClient.instance.dio.get('/tickets');
  ///   return res.data;
  /// } catch (e) {
  ///   throw ApiClient.instance.mapError(e);
  /// }
  /// ```
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
                      (e as Map).map((k, v) => MapEntry(k.toString(), v?.toString()))))
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
