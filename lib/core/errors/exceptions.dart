/// Base exception class for the application
/// Exceptions are thrown by the data layer
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'AppException[$code]: $message';
    }
    return 'AppException: $message';
  }
}

// ============================================================================
// Server Exceptions
// ============================================================================

class ServerException extends AppException {
  ServerException({
    String message = 'Server error occurred',
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);
}

class NetworkException extends AppException {
  NetworkException({String message = 'Network error occurred'})
      : super(message, code: 'NETWORK_ERROR');
}

class TimeoutException extends AppException {
  TimeoutException({String message = 'Request timeout'})
      : super(message, code: 'TIMEOUT');
}

// ============================================================================
// Auth Exceptions
// ============================================================================

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

class InvalidCredentialsException extends AppException {
  InvalidCredentialsException({String message = 'Invalid credentials'})
      : super(message, code: 'INVALID_CREDENTIALS');
}

class UserNotFoundException extends AppException {
  UserNotFoundException({String message = 'User not found'})
      : super(message, code: 'USER_NOT_FOUND');
}

class EmailAlreadyInUseException extends AppException {
  EmailAlreadyInUseException({String message = 'Email already in use'})
      : super(message, code: 'EMAIL_IN_USE');
}

class SessionExpiredException extends AppException {
  SessionExpiredException({String message = 'Session expired'})
      : super(message, code: 'SESSION_EXPIRED');
}

// ============================================================================
// NISN Exceptions
// ============================================================================

class NisnNotFoundException extends AppException {
  NisnNotFoundException({String message = 'NISN not found in registry'})
      : super(message, code: 'NISN_NOT_FOUND');
}

class NisnAlreadyUsedException extends AppException {
  NisnAlreadyUsedException({String message = 'NISN already registered'})
      : super(message, code: 'NISN_ALREADY_USED');
}

class InvalidNisnException extends AppException {
  InvalidNisnException({String message = 'Invalid NISN format'})
      : super(message, code: 'INVALID_NISN');
}

// ============================================================================
// Cache Exceptions
// ============================================================================

class CacheException extends AppException {
  CacheException({String message = 'Cache error occurred'})
      : super(message, code: 'CACHE_ERROR');
}

class CacheNotFoundException extends AppException {
  CacheNotFoundException({String message = 'Data not found in cache'})
      : super(message, code: 'CACHE_NOT_FOUND');
}

// ============================================================================
// Storage Exceptions
// ============================================================================

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.details});
}

class FileUploadException extends AppException {
  FileUploadException({String message = 'File upload failed'})
      : super(message, code: 'UPLOAD_FAILED');
}

class FileSizeExceededException extends AppException {
  FileSizeExceededException({String message = 'File size exceeds limit'})
      : super(message, code: 'FILE_TOO_LARGE');
}

class InvalidFileTypeException extends AppException {
  InvalidFileTypeException({String message = 'Invalid file type'})
      : super(message, code: 'INVALID_FILE_TYPE');
}

// ============================================================================
// Validation Exceptions
// ============================================================================

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(super.message, {this.fieldErrors, super.code = 'VALIDATION_ERROR'});
}

// ============================================================================
// Permission Exceptions
// ============================================================================

class PermissionException extends AppException {
  PermissionException({String message = 'Permission denied'})
      : super(message, code: 'PERMISSION_DENIED');
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String message = 'Unauthorized access'})
      : super(message, code: 'UNAUTHORIZED');
}

// ============================================================================
// Data Exceptions
// ============================================================================

class DataNotFoundException extends AppException {
  DataNotFoundException({String message = 'Data not found'})
    : super(message, code: 'DATA_NOT_FOUND');
}

class DataParsingException extends AppException {
  DataParsingException({
    String message = 'Failed to parse data',
    dynamic details,
  }) : super(message, code: 'PARSE_ERROR', details: details);
}

// ============================================================================
// RLS (Row Level Security) Exceptions
// ============================================================================

class RLSException extends AppException {
  RLSException({String message = 'Access denied by row level security'})
    : super(message, code: 'RLS_DENIED');
}

// ============================================================================
// File/Storage Exceptions
// ============================================================================

class FileException extends AppException {
  FileException({String message = 'File operation failed', super.details})
      : super(message, code: 'FILE_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException({String message = 'Resource not found'})
      : super(message, code: 'NOT_FOUND');
}

