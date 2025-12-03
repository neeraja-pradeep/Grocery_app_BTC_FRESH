import 'package:dio/dio.dart';

enum NetworkErrorType {
  /// Device has no internet connection
  noInternet,

  /// Connection timeout - device has connectivity but server is not responding
  timeout,

  /// Server returned an error (5xx)
  serverError,

  /// Bad request or client error (4xx)
  clientError,

  /// Unknown error
  unknown,
}

class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.statusCode,
    this.type,
    this.body,
    this.errorType = NetworkErrorType.unknown,
  });

  final String message;
  final int? statusCode;
  final DioExceptionType? type;
  final dynamic body;
  final NetworkErrorType errorType;

  factory NetworkException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final body = response?.data;

    String message = error.message ?? 'Unexpected network error';
    NetworkErrorType errorType = NetworkErrorType.unknown;

    // Determine error type based on DioException type
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Check your internet connection.';
        errorType = NetworkErrorType.timeout;
        break;

      case DioExceptionType.connectionError:
        message =
            'Failed to connect. Check your internet connection and try again.';
        errorType = NetworkErrorType.noInternet;
        break;

      case DioExceptionType.badResponse:
        if (statusCode != null && statusCode >= 500) {
          message = 'Server error ($statusCode). Please try again later.';
          errorType = NetworkErrorType.serverError;
        } else if (statusCode != null && statusCode >= 400) {
          message = 'Request failed ($statusCode). Please check your input.';
          errorType = NetworkErrorType.clientError;
        } else {
          message = 'Request failed with status $statusCode';
          errorType = NetworkErrorType.unknown;
        }
        break;

      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        errorType = NetworkErrorType.unknown;
        break;

      case DioExceptionType.unknown:
      default:
        if (statusCode != null) {
          message = 'Request failed with status $statusCode';
        }
        errorType = NetworkErrorType.unknown;
        break;
    }

    return NetworkException(
      message: message,
      statusCode: statusCode,
      type: error.type,
      body: body,
      errorType: errorType,
    );
  }

  /// Check if this error is due to no internet connection
  bool get isNoInternet => errorType == NetworkErrorType.noInternet;

  /// Check if this error is due to timeout
  bool get isTimeout => errorType == NetworkErrorType.timeout;

  /// Check if this error is due to server error (5xx)
  bool get isServerError => errorType == NetworkErrorType.serverError;

  /// Check if this error is due to client error (4xx)
  bool get isClientError => errorType == NetworkErrorType.clientError;

  @override
  String toString() =>
      'NetworkException(type: $errorType, statusCode: $statusCode, message: $message)';
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
