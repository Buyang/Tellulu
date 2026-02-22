/// Typed exceptions for the Tellulu app.
///
/// Use these instead of returning null or swallowing generic exceptions.
/// Callers can catch specific types to provide appropriate user feedback.

/// Base exception class for all Tellulu errors.
class TelluluException implements Exception {
  TelluluException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'TelluluException($code): $message';
}

/// Thrown when an API key is missing or invalid.
class ApiKeyMissingException extends TelluluException {
  ApiKeyMissingException(String service)
      : super('$service API key is not configured', code: 'API_KEY_MISSING');
}

/// Thrown when the API rate limit is exceeded.
class ApiRateLimitException extends TelluluException {
  ApiRateLimitException({Duration? retryAfter})
      : retryAfter = retryAfter ?? const Duration(seconds: 60),
        super('API rate limit exceeded. Try again later.', code: 'RATE_LIMIT');

  final Duration retryAfter;
}

/// Thrown when content is blocked by a safety filter.
class SafetyFilterException extends TelluluException {
  SafetyFilterException({String? reason})
      : super(reason ?? 'Content was blocked by the safety filter.', code: 'SAFETY_FILTER');
}

/// Thrown when StorageService is accessed before initialization.
class StorageNotInitializedException extends TelluluException {
  StorageNotInitializedException()
      : super('StorageService not initialized. Call init() first.', code: 'NOT_INITIALIZED');
}

/// Thrown when a network request fails (non-retryable).
class NetworkException extends TelluluException {
  NetworkException(super.message, {super.code, this.statusCode});

  final int? statusCode;
}
