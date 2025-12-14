import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../models/coupon_dto.dart';

/// Response model for coupon list with cache headers
class CouponListRemoteResponse {
  CouponListRemoteResponse({
    required this.couponList,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final CouponListResponseDto couponList;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
}

/// Remote data source for fetching coupons from API
abstract class CouponRemoteDataSource {
  /// Fetch coupon list with conditional headers (supports 304 Not Modified)
  /// Returns null if server responds with 304 (not modified)
  Future<CouponListRemoteResponse?> fetchCouponList({
    String? ifNoneMatch,
    String? ifModifiedSince,
  });
}

/// Implementation using API Client (DIO)
class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  CouponRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CouponListRemoteResponse?> fetchCouponList({
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
          'SENDING CONDITIONAL REQUEST for coupons\nHeaders: ${headers.toString()}',
          name: 'CouponRemoteDataSource',
          level: 700,
        );
      } else {
        developer.log(
          'SENDING UNCONDITIONAL REQUEST for coupons (no cache)',
          name: 'CouponRemoteDataSource',
          level: 700,
        );
      }

      final response = await _apiClient.get(
        '/api/order/v1/coupons/',
        headers: headers.isNotEmpty ? headers : null,
      );

      final statusCode = response.statusCode ?? 200;
      final responseHeaders = response.headers;

      // Handle 304 Not Modified
      if (statusCode == 304) {
        developer.log(
          'Coupons: HTTP 304 (bandwidth optimized)',
          name: 'RemoteDataSource',
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
        'Coupons: HTTP 200 (Last-Modified: $lastModified)',
        name: 'RemoteDataSource',
      );

      return CouponListRemoteResponse(
        couponList: CouponListResponseDto.fromJson(
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
          'Coupons: HTTP 304 (via NetworkException)',
          name: 'RemoteDataSource',
        );
        return null;
      }
      developer.log(
        'Coupons: NetworkException - $error',
        name: 'RemoteDataSource',
      );
      rethrow;
    } on DioException catch (error) {
      developer.log('Coupons: DioException - $error', name: 'RemoteDataSource');
      throw NetworkException.fromDio(error);
    } on FormatException catch (error) {
      developer.log(
        'Coupons: FormatException - $error',
        name: 'RemoteDataSource',
      );
      throw NetworkException(message: error.message);
    } catch (e) {
      developer.log('Coupons: Error - $e', name: 'RemoteDataSource');
      rethrow;
    }
  }
}
