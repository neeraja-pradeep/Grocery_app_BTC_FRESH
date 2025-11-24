import 'package:dio/dio.dart';
import 'package:grocery_app/core/error/failure.dart';

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

Failure mapDioError(Object e) {
  // IMPORTANT: prevent double mapping
  if (e is Failure) return e;

  if (e is DioException) {
    final data = e.response?.data;

    // Read error message safely
    final msg = (data is Map)
        ? (data["message"] ?? data["error"] ?? data["detail"])
        : null;

    final status = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppFailure("Connection timed out. Please try again.");

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.message?.contains("SocketException") ?? false) {
          return const AppFailure("No internet connection.");
        }
        return const AppFailure("Network error occurred.");

      case DioExceptionType.badCertificate:
        return const AppFailure(
          "Bad SSL certificate. Unable to connect safely.",
        );

      case DioExceptionType.badResponse:
        // If backend sent a readable error message -> show it
        if (msg is String && msg.isNotEmpty) {
          return AppFailure(msg);
        }

        // Fallback by HTTP status code
        switch (status) {
          case 400:
            return const AppFailure("Invalid Number.");
          case 401:
            return const AppFailure("Unauthorized. Please log in.");
          case 403:
            return const AppFailure("Access denied.");
          case 404:
            return const AppFailure("Invalid Number.");
          case 500:
            return const AppFailure("Server error. Please try again later.");
        }

        return const AppFailure("Something went wrong. Please try again.");

      case DioExceptionType.cancel:
        return const AppFailure("Request was cancelled.");
    }
  }

  return const AppFailure("Unexpected error. Please try again.");
}
