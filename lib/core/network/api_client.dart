import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import 'endpoints.dart';
import 'network_exceptions.dart';

class ApiClient {
  late Dio dio;
  late PersistCookieJar cookieJar;

  // Use centralized configuration
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Duration get _defaultConnectTimeout => AppConfig.connectTimeout;
  static Duration get _defaultReceiveTimeout => AppConfig.receiveTimeout;

  // Guest mode check function - will be set by main.dart
  bool Function()? isGuestMode;

  ApiClient();

  Future<void> init() async {
    // 1. CookieJar init
    final dir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies'));

    // 2. Create dio with options
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: _defaultConnectTimeout,
        receiveTimeout: _defaultReceiveTimeout,
        sendTimeout: _defaultConnectTimeout,
        responseType: ResponseType.json,
        contentType: 'application/json',
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // 3. Cookies
    dio.interceptors.add(CookieManager(cookieJar));

    // Note: Authentication is handled via session cookies (CookieManager above)
    // No additional user context headers needed for authenticated requests

    // 5. Debug logging
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

    // 6. Guest mode & CSRF interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check if user is in guest mode
          final isGuest = isGuestMode?.call() ?? false;

          if (isGuest) {
            // For guest mode: Use 'dev: 2' header, skip CSRF
            options.headers['dev'] = '2';
          } else {
            // For authenticated users: Use CSRF token
            final csrf = await _getCsrfToken();
            if (csrf != null) {
              options.headers['X-CSRFToken'] = csrf;
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Helper for CSRF token
  Future<String?> _getCsrfToken() async {
    final cookies = await cookieJar.loadForRequest(
      Uri.parse(dio.options.baseUrl),
    );

    final csrfCookie = cookies.firstWhere(
      (c) => c.name.toLowerCase() == 'csrftoken',
      orElse: () => Cookie('', ''),
    );

    return csrfCookie.value.isEmpty ? null : csrfCookie.value;
  }

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedHeaders = {
        if (options?.headers != null) ...options!.headers!,
        if (headers != null) ...headers,
      };

      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(
          headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        ),
      );

      return response;
    } on DioException catch (error) {
      throw NetworkException.fromDio(error);
    }
  }

  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedHeaders = {
        if (options?.headers != null) ...options!.headers!,
        if (headers != null) ...headers,
      };

      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(
          headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        ),
      );

      return response;
    } on DioException catch (error) {
      throw NetworkException.fromDio(error);
    }
  }

  // PATCH
  Future<Response<T>> patch<T>(
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

      final response = await dio.patch<T>(
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

  // DELETE
  Future<Response<T>> delete<T>(
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

      final response = await dio.delete<T>(
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

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('ApiClient must be overridden in main.dart');
});
