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
