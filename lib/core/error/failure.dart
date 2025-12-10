/// Base failure type used across the entire app.
abstract class Failure {
  final String message; // User-facing message
  final String? technicalDetails; // Optional developer/debug info

  const Failure(this.message, [this.technicalDetails]);

  String get displayMessage => message;

  @override
  String toString() =>
      '$runtimeType(message: $message, technical: $technicalDetails)';
}

// ------------------------------
// Generic App Failures
// ------------------------------

/// Default catch-all failure (unexpected errors)
class AppFailure extends Failure {
  const AppFailure(super.message, [super.technicalDetails]);
}

// ------------------------------
// Network-level Failures
// ------------------------------

class NetworkFailure extends Failure {
  const NetworkFailure([String? details])
    : super('No internet connection', details);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('Request timed out');
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

/// Represents a failure when loading/saving to local storage (Cache).
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Represents a failure when data format is invalid or parsing fails.
class DataParsingFailure extends Failure {
  const DataParsingFailure(super.message);
}

/// Represents an unknown or unexpected error.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// ------------------------------
// Auth-specific Failures
// ------------------------------

class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure() : super('Invalid OTP. Please check and try again.');
}

class OtpExpiredFailure extends Failure {
  const OtpExpiredFailure() : super('OTP has expired. Request a new one.');
}

class TooManyAttemptsFailure extends Failure {
  final int retryAfterSeconds;

  const TooManyAttemptsFailure(this.retryAfterSeconds)
    : super('Too many attempts. Try again in $retryAfterSeconds seconds.');
}

class MobileAlreadyExistsFailure extends Failure {
  const MobileAlreadyExistsFailure()
    : super('This mobile number is already registered.');
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure()
    : super(
        'Password must be at least 8 characters with 1 uppercase and 1 number.',
      );
}

class PasswordMismatchFailure extends Failure {
  const PasswordMismatchFailure() : super('Passwords do not match.');
}

class InvalidNameFailure extends Failure {
  const InvalidNameFailure() : super('Name must be at least 2 characters.');
}

class InvalidMobileNumberFailure extends Failure {
  const InvalidMobileNumberFailure() : super('Invalid mobile number format.');
}

class NotAuthenticatedFailure extends Failure {
  const NotAuthenticatedFailure() : super('Please log in to continue.');
}

// Storage failures
class CacheReadFailure extends Failure {
  CacheReadFailure([String? details])
    : super('Failed to read cached data', details);
}

class CacheWriteFailure extends Failure {
  CacheWriteFailure([String? details])
    : super('Failed to save data locally', details);
}

// ------------------------------
// Exceptions (for throwing)
// ------------------------------

/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when server returns an error (5xx, 4xx)
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

/// Exception thrown when there are network connectivity issues
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Exception thrown when resource is not found (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Exception thrown when user is not authorized (401, 403)
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

/// Exception thrown when data format is invalid or parsing fails
class DataParsingException extends AppException {
  const DataParsingException(super.message);
}

/// Exception thrown when request times out
class TimeoutException extends AppException {
  const TimeoutException(super.message);
}

/// Exception thrown for cache-related errors
class CacheException extends AppException {
  const CacheException(super.message);
}
