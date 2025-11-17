// lib/core/network/network_exceptions.dart

/// Network-related exceptions
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super('Request timeout');
}

class NoInternetException extends NetworkException {
  const NoInternetException() : super('No internet connection');
}

class ServerException extends NetworkException {
  final int statusCode;

  const ServerException(this.statusCode, String message) : super(message);
}
