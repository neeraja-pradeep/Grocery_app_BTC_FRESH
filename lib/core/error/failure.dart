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

  const ServerFailure({this.statusCode, String? details})
    : super('Server error occurred', details);
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
