import 'package:dio/dio.dart';

class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.statusCode,
    this.type,
    this.body,
  });

  final String message;
  final int? statusCode;
  final DioExceptionType? type;
  final dynamic body;

  factory NetworkException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final body = response?.data;

    String message = error.message ?? 'Unexpected network error';
    if (statusCode != null) {
      message = 'Request failed with status $statusCode';
    }

    return NetworkException(
      message: message,
      statusCode: statusCode,
      type: error.type,
      body: body,
    );
  }

  @override
  String toString() =>
      'NetworkException(statusCode: $statusCode, message: $message)';
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super(message: 'Request timeout');
}

class NoInternetException extends NetworkException {
  const NoInternetException() : super(message: 'No internet connection');
}

class ServerException extends NetworkException {
  const ServerException(int statusCode, String message)
      : super(message: message, statusCode: statusCode);
}
