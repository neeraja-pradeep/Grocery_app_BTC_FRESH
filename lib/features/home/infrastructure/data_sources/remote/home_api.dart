// lib/features/home/infrastructure/data_sources/remote/home_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/core/utils/logger.dart';
import 'package:new_app/features/home/domain/entities/banner.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart'; // For PaginatedResult

abstract class HomeRemoteDataSource {
  Future<PaginatedResult<Category>> getCategories({int page = 1});

  Future<List<ProductVariant>> getDiscountedProducts({
    int? categoryId,
    String? categoryName,
    String? parentCategoryName,
    double? minPrice,
    double? maxPrice,
    String ordering,
  });

  Future<PaginatedResult<Banner>> getBanners({int page = 1});

  Future<List<ProductVariant>> searchProducts({
    required String query,
    int page = 1,
  });

  Future<UserAddress?> getSelectedAddress();

  Future<List<ProductVariant>> getBestDeals({int limit = 10});
}

class HomeApiImpl implements HomeRemoteDataSource {
  final Dio _dio;
  HomeApiImpl(this._dio);

  // --- Helper Methods ---

  /// Converts DioException to appropriate custom exception
  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const TimeoutException(
          'Connection timeout - Please check your internet connection',
        );
      case DioExceptionType.sendTimeout:
        return const TimeoutException('Request timeout - Please try again');
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Server taking too long to respond');
      case DioExceptionType.connectionError:
        return const NetworkException(
          'No internet connection - Please check your network',
        );
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';

        switch (statusCode) {
          case 400:
            return ServerException(
              'Bad request: $message',
              statusCode: statusCode,
            );
          case 401:
            return const UnauthorizedException(
              'Session expired - Please login again',
            );
          case 403:
            return const UnauthorizedException(
              'Access denied - Insufficient permissions',
            );
          case 404:
            return const NotFoundException('Resource not found');
          case 422:
            return ServerException(
              'Validation error: $message',
              statusCode: statusCode,
            );
          case 429:
            return const ServerException(
              'Too many requests - Please try again later',
            );
          case 500:
            return const ServerException(
              'Server error - Please try again later',
            );
          case 502:
            return const ServerException(
              'Bad gateway - Server is temporarily unavailable',
            );
          case 503:
            return const ServerException(
              'Service unavailable - Please try again later',
            );
          default:
            return ServerException(
              'Server error ($statusCode): $message',
              statusCode: statusCode,
            );
        }
      case DioExceptionType.unknown:
        return ServerException('Network error: ${e.message}');
      default:
        return ServerException('Unexpected error: ${e.message}');
    }
  }

  Future<PaginatedResult<T>> _fetchPaginated<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Validate response data
      if (response.data == null) {
        throw const ServerException('Empty response from server');
      }

      final data = response.data as Map<String, dynamic>;

      // Safely handle results array
      final results = data['results'] as List? ?? [];

      return PaginatedResult(
        count: data['count'] ?? 0,
        next: data['next'],
        previous: data['previous'],
        results: results
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on FormatException catch (e) {
      throw DataParsingException('Invalid data format: $e');
    } on TypeError catch (e) {
      throw DataParsingException('Data type mismatch: $e');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  Future<List<T>> _fetchList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Validate response data
      if (response.data == null) {
        throw const ServerException('Empty response from server');
      }

      List listData;
      if (response.data is Map && response.data.containsKey('results')) {
        listData = response.data['results'] ?? [];
      } else if (response.data is List) {
        listData = response.data as List;
      } else {
        throw const DataParsingException('Unexpected response format');
      }

      // Debug logging for product data
      if (path.contains('variants') && listData.isNotEmpty) {
        Logger.debug(
          'API Response - Product data sample',
          data: {
            'endpoint': path,
            'first_product': listData.first,
            'total_products': listData.length,
          },
        );
      }

      return listData.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on FormatException catch (e) {
      throw DataParsingException('Invalid data format: $e');
    } on TypeError catch (e) {
      throw DataParsingException('Data type mismatch: $e');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  // --- Implementation ---

  @override
  Future<PaginatedResult<Category>> getCategories({int page = 1}) {
    return _fetchPaginated(
      '/api/products/category/', // Updated endpoint
      queryParameters: {'page': page},
      fromJson: Category.fromJson,
    );
  }

  @override
  Future<List<ProductVariant>> getDiscountedProducts({
    int? categoryId,
    String? categoryName,
    String? parentCategoryName,
    double? minPrice,
    double? maxPrice,
    String ordering = '-discounted_price',
  }) {
    final params = {
      'ordering': ordering,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (parentCategoryName != null)
        'parent_category_name': parentCategoryName,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };

    return _fetchList(
      '/api/products/variants/discounts/', // Updated endpoint
      queryParameters: params,
      fromJson: ProductVariant.fromJson,
    );
  }

  @override
  Future<PaginatedResult<Banner>> getBanners({int page = 1}) {
    return _fetchPaginated(
      '/api/products/banners/',
      queryParameters: {'page': page},
      fromJson: Banner.fromJson,
    );
  }

  @override
  Future<List<ProductVariant>> searchProducts({
    required String query,
    int page = 1,
  }) {
    // Note: The requirement says "Returns Paginated... (if it works)".
    // But the return type requested is List<ProductVariant>.
    // I am extracting the list to match the signature.
    return _fetchList(
      '/api/products/variants/',
      queryParameters: {'search': query, 'page': page},
      fromJson: ProductVariant.fromJson,
    );
  }

  @override
  Future<UserAddress?> getSelectedAddress() async {
    try {
      final response = await _dio.get('/api/users/address/selected/');

      if (response.data == null) {
        return null;
      }

      return UserAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // For address, 404 is acceptable (no address selected)
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioException(e);
    } on FormatException catch (e) {
      throw DataParsingException('Invalid address data format: $e');
    } catch (e) {
      throw ServerException('Error fetching address: $e');
    }
  }

  @override
  Future<List<ProductVariant>> getBestDeals({int limit = 10}) {
    return _fetchList(
      '/api/products/variants/',
      queryParameters: {
        'limit': limit,
        'ordering': '-discounted_price',
        'has_discount': 'true',
      },
      fromJson: ProductVariant.fromJson,
    );
  }
}

// Dio Provider
final dioProvider = riverpod.Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl =
      'http://156.67.104.149:8080'; // Replace with your actual base URL
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);

  dio.options.headers['dev'] = '2';

  return dio;
});

final homeRemoteDataSourceProvider = riverpod.Provider<HomeRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return HomeApiImpl(dio);
});
