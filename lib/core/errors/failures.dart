import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Failures represent errors that are part of the business logic
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Auth Failures
// ============================================================================

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid email or password',
  ]);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'User not found']);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'Email already in use']);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([super.message = 'Password is too weak']);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([super.message = 'Invalid email format']);
}

// ============================================================================
// NISN Failures
// ============================================================================

class NisnNotFoundFailure extends Failure {
  const NisnNotFoundFailure([super.message = 'NISN not registered in system']);
}

class NisnAlreadyUsedFailure extends Failure {
  const NisnAlreadyUsedFailure([
    super.message = 'NISN already used by another account',
  ]);
}

class InvalidNisnFailure extends Failure {
  const InvalidNisnFailure([super.message = 'Invalid NISN format']);
}

// ============================================================================
// Network Failures
// ============================================================================

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'})
    : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection error'})
    : super(message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({String message = 'Request timeout'}) : super(message);
}

// ============================================================================
// Cache Failures
// ============================================================================

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class CacheNotFoundFailure extends Failure {
  const CacheNotFoundFailure([super.message = 'Data not found in cache']);
}

// ============================================================================
// Storage Failures
// ============================================================================

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error occurred']);
}

class FileUploadFailure extends Failure {
  const FileUploadFailure([super.message = 'File upload failed']);
}

class FileSizeExceededFailure extends Failure {
  const FileSizeExceededFailure([
    super.message = 'File size exceeds maximum limit',
  ]);
}

class InvalidFileTypeFailure extends Failure {
  const InvalidFileTypeFailure([super.message = 'Invalid file type']);
}

class FileFailure extends Failure {
  const FileFailure({String message = 'File operation failed'})
    : super(message);
}

// ============================================================================
// Permission Failures
// ============================================================================

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

// ============================================================================
// Validation Failures
// ============================================================================

class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Validation error'})
    : super(message);
}

class RequiredFieldFailure extends Failure {
  const RequiredFieldFailure([super.message = 'Required field is empty']);
}

// ============================================================================
// Data Failures
// ============================================================================

class DataNotFoundFailure extends Failure {
  const DataNotFoundFailure([super.message = 'Data not found']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Resource not found'})
    : super(message);
}

class DataParsingFailure extends Failure {
  const DataParsingFailure([super.message = 'Failed to parse data']);
}

// ============================================================================
// Unknown Failure
// ============================================================================

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error occurred']);
}
