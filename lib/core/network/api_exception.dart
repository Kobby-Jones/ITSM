/// Typed exceptions surfaced by [ApiClient] so UI code can react appropriately
/// (show a snackbar, prompt re-login, queue for offline retry, etc.) instead
/// of pattern-matching on raw Dio exceptions.
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// No network reachable / request timed out. Callers should typically queue
/// the write for later sync rather than surface a hard error.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection']);
}

/// 401 — token missing/invalid/expired and refresh also failed. Caller should
/// force a re-login.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired. Please sign in again.']);
}

/// 403 — authenticated but not permitted.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = "You don't have permission to do that."]);
}

/// 404.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found']);
}

/// 409 — conflict (e.g. duplicate email, stale offline write).
class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict with existing data']);
}

/// 400/422 — validation failed. [errors] mirrors the backend's
/// `{ field, message }[]` shape from `ApiResponse.badRequest`.
class ValidationException extends ApiException {
  final List<Map<String, String?>> errors;
  const ValidationException(super.message, {this.errors = const []});
}

/// 429 — rate limited.
class RateLimitException extends ApiException {
  const RateLimitException([super.message = 'Too many requests. Please slow down.']);
}

/// 5xx or anything unexpected.
class ServerException extends ApiException {
  final int? statusCode;
  const ServerException([super.message = 'Something went wrong on the server.', this.statusCode]);
}
