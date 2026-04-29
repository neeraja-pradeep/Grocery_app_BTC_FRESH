// lib/features/home/infrastructure/data_sources/remote/home_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../../../core/error/failure.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/user_address.dart';
import '../../../domain/repositories/home_repository.dart';

abstract class HomeRemoteDataSource {
  Future<PaginatedResult<Category>> getCategories({int page = 1});

  Future<DiscountedProductsResult> getDiscountedProducts({
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

  Future<PaginatedResult<Product>> searchProductsWithVariants({
    required String query,
    int page = 1,
  });

  Future<UserAddress?> getSelectedAddress();

  Future<List<ProductVariant>> getBestDeals({int limit = 10});
}

class HomeApiImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;
  HomeApiImpl(this._apiClient);

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
        final responseData = e.response?.data;
        final message =
            (responseData is Map ? responseData['message'] : null) ??
            e.message ??
            'Unknown error';

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
      final response = await _apiClient.get(
        path,
        queryParameters: queryParameters,
      );

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
      final response = await _apiClient.get(
        path,
        queryParameters: queryParameters,
      );

      // Validate response data
      if (response.data == null) {
        throw const ServerException('Empty response from server');
      }

      List listData;
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        listData = (data['results'] as List?) ?? [];
      } else if (data is List) {
        listData = data;
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
      '/api/products/v1/category/', // Updated endpoint
      queryParameters: {'page': page},
      fromJson: Category.fromJson,
    );
  }

  @override
  Future<DiscountedProductsResult> getDiscountedProducts({
    int? categoryId,
    String? categoryName,
    String? parentCategoryName,
    double? minPrice,
    double? maxPrice,
    String ordering = '-discounted_price',
  }) async {
    // Hit the products endpoint instead of the variants/discounts/ endpoint.
    // The products endpoint embeds category_id / category_name on each product,
    // which lets the grouping use case match category by id (correct ID space)
    // instead of comparing variant.productId against category.id.
    final params = <String, dynamic>{
      'is_discounted': 'true',
      'ordering': ordering,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (parentCategoryName != null)
        'parent_category_name': parentCategoryName,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };

    final products = await _fetchList(
      '/api/products/v1/',
      queryParameters: params,
      fromJson: Product.fromJson,
    );

    final variants = <ProductVariant>[];
    final productCategoryMap = <int, int>{};
    for (final product in products) {
      productCategoryMap[product.id] = product.categoryId;
      variants.addAll(product.variants);
    }

    return DiscountedProductsResult(
      variants: variants,
      productCategoryMap: productCategoryMap,
    );
  }

  @override
  Future<PaginatedResult<Banner>> getBanners({int page = 1}) {
    return _fetchPaginated(
      '/api/products/v1/banners/',
      queryParameters: {'page': page},
      fromJson: Banner.fromJson,
    );
  }

  @override
  Future<List<ProductVariant>> searchProducts({
    required String query,
    int page = 1,
  }) {
    // Use 'search' parameter on variants endpoint
    // http://156.67.104.149:8080/api/products/v1/variants/?search=ri
    return _fetchList(
      '/api/products/v1/variants/',
      queryParameters: {'search': query, 'page': page},
      fromJson: ProductVariant.fromJson,
    );
  }

  @override
  Future<UserAddress?> getSelectedAddress() async {
    try {
      final response = await _apiClient.get(
        '/api/auth/v1/address/',
        queryParameters: {'selected': 'true'},
      );

      Logger.debug('getSelectedAddress response: ${response.data}');

      if (response.data == null) {
        Logger.debug('getSelectedAddress: response.data is null');
        return null;
      }

      // Response is paginated: { "count": 1, "results": [...] }
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List?;

      Logger.debug('getSelectedAddress: results count: ${results?.length}');

      if (results == null || results.isEmpty) {
        Logger.debug('getSelectedAddress: No selected address found');
        return null;
      }

      final address = UserAddress.fromJson(
        results.first as Map<String, dynamic>,
      );
      Logger.debug(
        'getSelectedAddress: Parsed address: streetAddress1=${address.streetAddress1}, streetAddress2=${address.streetAddress2}',
      );
      return address;
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
      '/api/products/v1/variants/',
      queryParameters: {
        'limit': limit,
        'ordering': '-discounted_price',
        'has_discount': 'true',
      },
      fromJson: ProductVariant.fromJson,
    );
  }

  @override
  Future<PaginatedResult<Product>> searchProductsWithVariants({
    required String query,
    int page = 1,
  }) {
    return _fetchPaginated(
      '/api/products/v1/',
      queryParameters: {'search': query, 'page': page},
      fromJson: Product.fromJson,
    );
  }
}

final homeRemoteDataSourceProvider = riverpod.Provider<HomeRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeApiImpl(apiClient);
});
