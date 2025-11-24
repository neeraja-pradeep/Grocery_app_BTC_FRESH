import 'dart:developer' as developer;
import 'package:dio/dio.dart';

/// Global HTTP conditional request headers helper
///
/// This utility provides reusable functions for implementing If-Modified-Since
/// and If-None-Match conditional request logic across all API endpoints.
///
/// HTTP Conditional Request Flow:
/// 1. Build conditional headers from cached metadata (lastModified, eTag)
/// 2. Send request with conditional headers
/// 3. Server responds:
///    - 304 Not Modified: Data unchanged, return null (don't refresh UI)
///    - 200 OK: Data changed, extract and cache new headers
///
/// Benefits:
/// - Reduces bandwidth: 304 responses are ~1KB vs full data (50-100KB)
/// - Improves responsiveness: Frequent polling without excessive data transfer
/// - Battery/data friendly: Minimal network activity when data unchanged
class CacheHeadersHelper {
  const CacheHeadersHelper._();

  /// Build conditional request headers from cached metadata
  ///
  /// Parameters:
  /// - [ifModifiedSince]: Last-Modified header from previous response (RFC 1123 format)
  /// - [ifNoneMatch]: ETag from previous response
  ///
  /// Returns: Map of headers to include in HTTP request
  ///
  /// Example:
  /// ```
  /// final cachedMetadata = await localDataSource.getCachedProductDetail(productId);
  /// final headers = CacheHeadersHelper.buildConditionalHeaders(
  ///   ifModifiedSince: cachedMetadata?.lastModified,
  ///   ifNoneMatch: cachedMetadata?.eTag,
  /// );
  /// final response = await apiClient.get('/api/products/1/', headers: headers);
  /// ```
  static Map<String, String> buildConditionalHeaders({
    String? ifModifiedSince,
    String? ifNoneMatch,
  }) {
    final headers = <String, String>{};

    if (ifNoneMatch != null) {
      headers['If-None-Match'] = ifNoneMatch;
    }
    if (ifModifiedSince != null) {
      headers['If-Modified-Since'] = ifModifiedSince;
    }

    return headers;
  }

  /// Extract cache headers from HTTP response
  ///
  /// Parameters:
  /// - [responseHeaders]: Headers from HTTP response
  ///
  /// Returns: Tuple of (eTag, lastModified) to cache for next request
  ///
  /// Note: Headers are case-insensitive in HTTP but servers may use different cases.
  /// This function checks both lowercase and proper case variants.
  ///
  /// Example:
  /// ```
  /// final response = await apiClient.get('/api/products/1/');
  /// final (eTag, lastModified) = CacheHeadersHelper.extractCacheHeaders(response.headers);
  /// await localDataSource.cacheProductDetailWithMetadata(
  ///   productId,
  ///   ProductDetailCacheDto(
  ///     lastSyncedAt: DateTime.now(),
  ///     eTag: eTag,
  ///     lastModified: lastModified,
  ///   ),
  /// );
  /// ```
  static (String?, String?) extractCacheHeaders(Headers responseHeaders) {
    final eTag = responseHeaders.value('etag') ?? responseHeaders.value('ETag');
    final lastModified =
        responseHeaders.value('last-modified') ??
        responseHeaders.value('Last-Modified');

    return (eTag, lastModified);
  }

  /// Check if response indicates "not modified" (304)
  ///
  /// Parameters:
  /// - [statusCode]: HTTP status code from response
  ///
  /// Returns: true if status is 304 Not Modified
  static bool isNotModified(int? statusCode) {
    return statusCode == 304;
  }

  /// Log conditional request details (for debugging)
  ///
  /// Call this before sending conditional request to log headers being sent
  static void logConditionalRequest({
    required String endpoint,
    required String resourceId,
    required Map<String, String> headers,
  }) {
    if (headers.isEmpty) {
      developer.log(
        'UNCONDITIONAL REQUEST to $endpoint/$resourceId (no cache)',
        name: 'CacheHeadersHelper',
      );
    } else {
      developer.log(
        'CONDITIONAL REQUEST to $endpoint/$resourceId\nHeaders: ${headers.toString()}',
        name: 'CacheHeadersHelper',
      );
    }
  }

  /// Log conditional response details (for debugging)
  ///
  /// Call this after receiving response to log status and extracted headers
  static void logConditionalResponse({
    required String endpoint,
    required String resourceId,
    required int? statusCode,
    required String? extractedLastModified,
  }) {
    if (statusCode == 304) {
      developer.log(
        '304 NOT MODIFIED from $endpoint/$resourceId (bandwidth optimized)',
        name: 'CacheHeadersHelper',
      );
    } else {
      developer.log(
        '200 OK from $endpoint/$resourceId\nLast-Modified: $extractedLastModified',
        name: 'CacheHeadersHelper',
      );
    }
  }
}

/// Extend Headers type for easier access
extension HeadersHelper on Headers {
  /// Get header value with case-insensitive key lookup
  /// Checks both lowercase and proper case variants
  String? getValue(String key) {
    return value(key.toLowerCase()) ?? value(key);
  }
}
