import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exceptions.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/checkout_line_dto.dart';

/// Exception thrown when there's insufficient stock for a product
class InsufficientStockException implements Exception {
  InsufficientStockException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Response model for checkout lines with cache headers
class CheckoutLinesRemoteResponse {
  CheckoutLinesRemoteResponse({
    required this.checkoutLines,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final CheckoutLinesResponseDto checkoutLines;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
}

/// Combined data source for checkout lines (remote API + local metadata cache)
class CheckoutLineDataSource {
  CheckoutLineDataSource(this._apiClient);

  final ApiClient _apiClient;
  static const String _cacheBoxName = 'checkout_lines_cache';
  static const String _lastModifiedKey = 'checkout_lines_last_modified';
  static const String _etagKey = 'checkout_lines_etag';

  /// Fetch checkout lines with conditional headers (supports 304 Not Modified)
  /// Returns null if server responds with 304 (not modified)
  Future<CheckoutLinesRemoteResponse?> fetchCheckoutLines({
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      final headers = <String, String>{};

      // Add conditional headers if provided
      if (ifNoneMatch != null) {
        headers['If-None-Match'] = ifNoneMatch;
      }
      if (ifModifiedSince != null) {
        headers['If-Modified-Since'] = ifModifiedSince;
      }

      // Log the request with conditional headers
      if (headers.isNotEmpty) {
        developer.log(
          'SENDING CONDITIONAL REQUEST for checkout lines\nHeaders: ${headers.toString()}',
          name: 'CheckoutLineDataSource',
          level: 700,
        );
      } else {
        developer.log(
          'SENDING UNCONDITIONAL REQUEST for checkout lines (no cache)',
          name: 'CheckoutLineDataSource',
          level: 700,
        );
      }

      final response = await _apiClient.get(
        '/api/order/v1/checkout-lines/',
        headers: headers.isNotEmpty ? headers : null,
      );

      final statusCode = response.statusCode ?? 200;
      final responseHeaders = response.headers;

      // Handle 304 Not Modified
      if (statusCode == 304) {
        developer.log(
          'Checkout lines: HTTP 304 (bandwidth optimized)',
          name: 'CheckoutLineDataSource',
        );
        return null; // Data hasn't changed
      }

      // Extract cache headers from response
      final eTag =
          responseHeaders.value('etag') ?? responseHeaders.value('ETag');
      final lastModified =
          responseHeaders.value('last-modified') ??
          responseHeaders.value('Last-Modified');

      developer.log(
        'Checkout lines: HTTP 200 (Last-Modified: $lastModified)',
        name: 'CheckoutLineDataSource',
      );

      return CheckoutLinesRemoteResponse(
        checkoutLines: CheckoutLinesResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        ),
        fetchedAt: DateTime.now(),
        eTag: eTag,
        lastModified: lastModified,
      );
    } on NetworkException catch (error) {
      // Handle 304 Not Modified wrapped in NetworkException
      if (error.statusCode == 304) {
        developer.log(
          'Checkout lines: HTTP 304 (via NetworkException)',
          name: 'CheckoutLineDataSource',
        );
        return null;
      }
      developer.log(
        'Checkout lines: NetworkException - $error',
        name: 'CheckoutLineDataSource',
      );
      rethrow;
    } on DioException catch (error) {
      developer.log(
        'Checkout lines: DioException - $error',
        name: 'CheckoutLineDataSource',
      );
      throw NetworkException.fromDio(error);
    } on FormatException catch (error) {
      developer.log(
        'Checkout lines: FormatException - $error',
        name: 'CheckoutLineDataSource',
      );
      throw NetworkException(message: error.message);
    } catch (e) {
      developer.log(
        'Checkout lines: Error - $e',
        name: 'CheckoutLineDataSource',
      );
      rethrow;
    }
  }

  /// Update checkout line quantity
  /// API body: { "product_variant_id": int, "quantity": int }
  /// [quantity] is a DELTA value: positive to add, negative to subtract
  Future<CheckoutLineDto> updateQuantity({
    required int lineId,
    required int productVariantId,
    required int quantity,
  }) async {
    try {
      developer.log(
        'PATCH REQUEST:\nURL: /api/order/checkout-lines/$lineId/\nData: {"product_variant_id": $productVariantId, "quantity": $quantity}',
        name: 'CheckoutLineDataSource',
      );

      final response = await _apiClient.patch(
        '/api/order/v1/checkout-lines/$lineId/',
        data: {'product_variant_id': productVariantId, 'quantity': quantity},
      );

      developer.log(
        'PATCH SUCCESS: Status ${response.statusCode}',
        name: 'CheckoutLineDataSource',
      );

      return CheckoutLineDto.fromJson(response.data as Map<String, dynamic>);
    } on NetworkException catch (error) {
      // ApiClient converts DioException to NetworkException, so we catch that
      developer.log(
        'PATCH FAILED:\nStatus: ${error.statusCode}\nBody: ${error.body}',
        name: 'CheckoutLineDataSource',
      );

      // Extract error message from response for 400 errors (insufficient stock)
      if (error.statusCode == 400 && error.body != null) {
        dynamic responseData = error.body;

        // Handle case where data is a String (needs JSON decoding)
        if (responseData is String) {
          try {
            responseData = Map<String, dynamic>.from(
              const JsonDecoder().convert(responseData) as Map,
            );
          } catch (_) {
            // If JSON decoding fails, continue with NetworkException
          }
        }

        if (responseData is Map<String, dynamic>) {
          // Check for quantity errors (insufficient stock)
          if (responseData.containsKey('quantity')) {
            final quantityErrors = responseData['quantity'];
            if (quantityErrors is List && quantityErrors.isNotEmpty) {
              throw InsufficientStockException(quantityErrors.first.toString());
            }
          }
          // Check for non_field_errors
          if (responseData.containsKey('non_field_errors')) {
            final errors = responseData['non_field_errors'];
            if (errors is List && errors.isNotEmpty) {
              throw InsufficientStockException(errors.first.toString());
            }
          }
          // Check for detail message
          if (responseData.containsKey('detail')) {
            throw InsufficientStockException(responseData['detail'].toString());
          }
        }
      }

      rethrow;
    }
  }

  /// Delete checkout line
  Future<void> deleteCheckoutLine(int lineId) async {
    try {
      developer.log(
        'DELETE REQUEST:\nURL: /api/order/v1/checkout-lines/$lineId/',
        name: 'CheckoutLineDataSource',
      );

      await _apiClient.delete('/api/order/v1/checkout-lines/$lineId/');

      developer.log('DELETE SUCCESS', name: 'CheckoutLineDataSource');
    } on DioException catch (error) {
      developer.log(
        'DELETE FAILED:\nStatus: ${error.response?.statusCode}\nMessage: ${error.message}\nResponse: ${error.response?.data}',
        name: 'CheckoutLineDataSource',
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Failed to delete checkout line: $e',
        name: 'CheckoutLineDataSource',
      );
      rethrow;
    }
  }

  /// Add item to cart (create checkout line)
  /// API body: { "product_variant_id": int, "quantity": int }
  Future<CheckoutLineDto> addToCart({
    required int productVariantId,
    required int quantity,
  }) async {
    try {
      developer.log(
        'POST REQUEST:\nURL: /api/order/v1/checkout-lines/\nData: {"product_variant_id": $productVariantId, "quantity": $quantity}',
        name: 'CheckoutLineDataSource',
      );

      final response = await _apiClient.post(
        '/api/order/v1/checkout-lines/',
        data: {'product_variant_id': productVariantId, 'quantity': quantity},
      );

      developer.log(
        'POST SUCCESS: Status ${response.statusCode}',
        name: 'CheckoutLineDataSource',
      );

      return CheckoutLineDto.fromJson(response.data as Map<String, dynamic>);
    } on NetworkException catch (error) {
      developer.log(
        'POST FAILED:\nStatus: ${error.statusCode}\nBody: ${error.body}',
        name: 'CheckoutLineDataSource',
      );

      // Extract error message from response for 400 errors (insufficient stock)
      if (error.statusCode == 400 && error.body != null) {
        dynamic responseData = error.body;

        // Handle case where data is a String (needs JSON decoding)
        if (responseData is String) {
          try {
            responseData = Map<String, dynamic>.from(
              const JsonDecoder().convert(responseData) as Map,
            );
          } catch (_) {
            // If JSON decoding fails, continue with NetworkException
          }
        }

        if (responseData is Map<String, dynamic>) {
          // Check for quantity errors (insufficient stock)
          if (responseData.containsKey('quantity')) {
            final quantityErrors = responseData['quantity'];
            if (quantityErrors is String) {
              throw InsufficientStockException(quantityErrors);
            }
            if (quantityErrors is List && quantityErrors.isNotEmpty) {
              throw InsufficientStockException(quantityErrors.first.toString());
            }
          }
          // Check for non_field_errors
          if (responseData.containsKey('non_field_errors')) {
            final errors = responseData['non_field_errors'];
            if (errors is List && errors.isNotEmpty) {
              throw InsufficientStockException(errors.first.toString());
            }
          }
          // Check for detail message
          if (responseData.containsKey('detail')) {
            throw InsufficientStockException(responseData['detail'].toString());
          }
        }
      }

      rethrow;
    } catch (e) {
      developer.log(
        'Failed to add item to cart: $e',
        name: 'CheckoutLineDataSource',
      );
      rethrow;
    }
  }

  /// Get cached metadata (Last-Modified, ETag)
  Future<Map<String, String?>> getCacheMetadata() async {
    final box = await Hive.openBox<String>(_cacheBoxName);
    return {
      'lastModified': box.get(_lastModifiedKey),
      'etag': box.get(_etagKey),
    };
  }

  /// Save cache metadata
  Future<void> saveCacheMetadata({String? lastModified, String? etag}) async {
    final box = await Hive.openBox<String>(_cacheBoxName);
    if (lastModified != null) {
      await box.put(_lastModifiedKey, lastModified);
    }
    if (etag != null) {
      await box.put(_etagKey, etag);
    }
  }

  /// Clear cache metadata
  Future<void> clearCacheMetadata() async {
    final box = await Hive.openBox<String>(_cacheBoxName);
    await box.clear();
  }
}
