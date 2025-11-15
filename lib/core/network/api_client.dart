import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'endpoints.dart';
import 'network_exceptions.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  final Dio _dio;

  static const _defaultConnectTimeout = Duration(seconds: 20);
  static const _defaultReceiveTimeout = Duration(seconds: 20);

  static Dio _createDefaultDio() {
    final baseOptions = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: _defaultConnectTimeout,
      receiveTimeout: _defaultReceiveTimeout,
      sendTimeout: _defaultConnectTimeout,
      responseType: ResponseType.json,
      contentType: 'application/json',
      validateStatus: (status) => status != null && status < 400,
      headers: const <String, dynamic>{'dev': '1'},
    );

    final dio = Dio(baseOptions);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }

    return dio;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedHeaders = <String, dynamic>{
        if (options?.headers != null) ...options!.headers!,
        if (headers != null) ...headers,
      };
      final requestHeaders = mergedHeaders.isEmpty ? null : mergedHeaders;

      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(headers: requestHeaders),
      );
      return response;
    } on DioException catch (error) {
      throw NetworkException.fromDio(error);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedHeaders = <String, dynamic>{
        if (options?.headers != null) ...options!.headers!,
        if (headers != null) ...headers,
      };
      final requestHeaders = mergedHeaders.isEmpty ? null : mergedHeaders;

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(headers: requestHeaders),
      );
      return response;
    } on DioException catch (error) {
      throw NetworkException.fromDio(error);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
