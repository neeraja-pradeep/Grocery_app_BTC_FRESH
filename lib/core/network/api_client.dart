import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'endpoints.dart';
import 'network_exceptions.dart';

class ApiClient {
  late Dio dio;
  late PersistCookieJar cookieJar;
  static const baseUrl = 'http://156.67.104.149:8080';

  static const _defaultConnectTimeout = Duration(seconds: 20);
  static const _defaultReceiveTimeout = Duration(seconds: 20);

  ApiClient();

  Future<void> init() async {
    // 1️⃣ CookieJar init
    final dir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies'));

    // 2️⃣ Create dio with your options + their baseUrl
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl, // ← YOUR BASE URL MANAGED HERE
        connectTimeout: _defaultConnectTimeout,
        receiveTimeout: _defaultReceiveTimeout,
        sendTimeout: _defaultConnectTimeout,
        responseType: ResponseType.json,
        contentType: 'application/json',
        validateStatus: (status) => status != null && status < 400,
        headers: const {'dev': '1'},
      ),
    );

    // 3️⃣ cookies
    dio.interceptors.add(CookieManager(cookieJar));

    // 4️⃣ debug logging
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

    // 5️⃣ CSRF interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final csrf = await _getCsrfToken();
          if (csrf != null) {
            options.headers['X-CSRFToken'] = csrf;
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

  // ---------------------------------------------------------------------------
  // 🌐 GET
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 🌐 POST
  // ---------------------------------------------------------------------------
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
}

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('ApiClient must be overridden in main.dart');
});
