// lib/core/error/failures.dart

/// Abstract class defining a failure in the application.
/// This is the base class for all errors returned by Repositories.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure from a remote server (API error, 500s, 404s).
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

/// Represents a failure when loading/saving to local storage (Cache).
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Represents a failure due to lack of internet connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Represents a failure when data format is invalid or parsing fails.
class DataParsingFailure extends Failure {
  const DataParsingFailure(super.message);
}

/// Represents an unknown or unexpected error.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
// lib/core/error/exceptions.dart

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
