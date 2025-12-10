import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cookieJarProvider = Provider<PersistCookieJar>((ref) {
  throw UnimplementedError('cookieJarProvider must be overridden at bootstrap');
});

// Dio provider
// Initially throws an error; will be overridden at bootstrap
final dioProvider = Provider<Dio>((ref) {
  throw UnimplementedError('dioProvider must be overridden at bootstrap');
});
