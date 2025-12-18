import 'package:dio/dio.dart';

import '../error/failure.dart';

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
        // Try to extract error message from response body
        String? bodyMessage;
        if (body is Map) {
          final rawMsg = body['message'] ?? body['error'] ?? body['detail'];
          if (rawMsg is String && rawMsg.isNotEmpty) {
            bodyMessage = rawMsg;
          }
        }

        if (statusCode != null && statusCode >= 500) {
          message =
              bodyMessage ??
              'Server error ($statusCode). Please try again later.';
          errorType = NetworkErrorType.serverError;
        } else if (statusCode != null && statusCode >= 400) {
          message =
              bodyMessage ??
              'Request failed ($statusCode). Please check your input.';
          errorType = NetworkErrorType.clientError;
        } else {
          message = bodyMessage ?? 'Request failed with status $statusCode';
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

Failure mapDioError(Object e) {
  // IMPORTANT: prevent double mapping
  if (e is Failure) return e;

  if (e is DioException) {
    final data = e.response?.data;

    // Read error message safely
    String? msg;
    if (data is Map) {
      // Check for standard error keys first - ensure it's a String
      final rawMsg = data['message'] ?? data['error'] ?? data['detail'];
      if (rawMsg is String) {
        msg = rawMsg;
      }

      // If no standard message, parse validation errors like {"username": ["error"]}
      if (msg == null) {
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            // Extract first error message from each field
            errors.add(value.first.toString());
          } else if (value is String) {
            // Handle direct string error messages
            errors.add(value);
          } else if (value is Map) {
            // Handle nested error objects
            final nestedMsg = value['message'] ?? value['error'];
            if (nestedMsg != null) {
              errors.add(nestedMsg.toString());
            }
          }
        });
        if (errors.isNotEmpty) {
          msg = errors.join('\n');
        }
      }
    }

    final status = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppFailure('Connection timed out. Please try again.');

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') ?? false) {
          return const AppFailure('No internet connection.');
        }
        return const AppFailure('Network error occurred.');

      case DioExceptionType.badCertificate:
        return const AppFailure(
          'Bad SSL certificate. Unable to connect safely.',
        );

      case DioExceptionType.badResponse:
        // If backend sent a readable error message -> show it
        if (msg is String && msg.isNotEmpty) {
          return AppFailure(msg);
        }

        // Fallback by HTTP status code
        switch (status) {
          case 400:
            return const AppFailure('Bad request. Please check your input.');
          case 401:
            return const AppFailure('Unauthorized. Please log in.');
          case 403:
            return const AppFailure('Access denied.');
          case 404:
            return const AppFailure('Resource not found.');
          case 500:
            return const AppFailure('Server error. Please try again later.');
        }

        return const AppFailure('Something went wrong. Please try again.');

      case DioExceptionType.cancel:
        return const AppFailure('Request was cancelled.');
    }
  }

  return const AppFailure('Unexpected error. Please try again.');
}
