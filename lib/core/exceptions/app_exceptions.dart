/// Custom exception classes for ArabiLogia Flutter app.
/// Provides structured error handling with Arabic messages.

/// NetworkException - for network-related errors (timeout, no connection, etc.)
class NetworkException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;

  const NetworkException(this.message, {this.originalError, this.code});

  @override
  String toString() => 'خطأ في الشبكة: $message';
}

/// AuthException - for authentication/authorization errors
class AuthException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;

  const AuthException(this.message, {this.originalError, this.code});

  @override
  String toString() => 'خطأ في المصادقة: $message';
}

/// DatabaseException - for Supabase/database errors
class DatabaseException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;

  const DatabaseException(this.message, {this.originalError, this.code});

  @override
  String toString() => 'خطأ في قاعدة البيانات: $message';
}

/// ValidationException - for input validation errors
class ValidationException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;
  final Map<String, String>? fieldErrors;

  const ValidationException(
    this.message, {
    this.originalError,
    this.code,
    this.fieldErrors,
  });

  @override
  String toString() => 'خطأ في التحقق: $message';
}

/// CacheException - for local storage/cache errors
class CacheException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;

  const CacheException(this.message, {this.originalError, this.code});

  @override
  String toString() => 'خطأ في التخزين المؤقت: $message';
}

/// UnknownException - fallback for unexpected errors
class UnknownException implements Exception {
  final String message;
  final Object? originalError;
  final String? code;

  const UnknownException(this.message, {this.originalError, this.code});

  @override
  String toString() => 'خطأ غير معروف: $message';
}
