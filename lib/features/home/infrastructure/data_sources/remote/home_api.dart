// lib/features/home/infrastructure/data_sources/remote/home_api.dart

import 'package:dio/dio.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/pagination.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/user_address.dart';
import '../../../domain/repositories/home_repository.dart';
import '../../models/paginated_result.dart';

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

  Future<Product> getProductById(int id);
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

  /// Like [_fetchPaginated] but keeps requesting `?page=N` until `next` is
  /// null, returning every page concatenated.
  ///
  /// The backend paginates at a fixed 25 and ignores `page_size`, so reading a
  /// single page silently truncates the list — the Home category grid was
  /// showing 25 of 40 categories for exactly this reason.
  Future<PaginatedResult<T>> _fetchAllPages<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
    int startPage = 1,
  }) async {
    final first = await _fetchPaginated(
      path,
      queryParameters: {...?queryParameters, 'page': startPage},
      fromJson: fromJson,
    );

    final all = <T>[...first.results];
    var hasNext = first.next != null;

    for (
      var page = startPage + 1;
      hasNext && page < startPage + kMaxPagesPerFetch;
      page++
    ) {
      final next = await _fetchPaginated(
        path,
        queryParameters: {...?queryParameters, 'page': page},
        fromJson: fromJson,
      );
      all.addAll(next.results);
      hasNext = next.next != null;
    }

    return PaginatedResult(
      count: first.count,
      // Fully drained, so there is nothing left to follow.
      next: null,
      previous: null,
      results: all,
    );
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

  /// Like [_fetchList] but keeps requesting `?page=N` until `next` is null.
  ///
  /// Endpoints that return a bare JSON array (no envelope) have no `next`, so
  /// they resolve after a single request exactly as [_fetchList] would.
  ///
  /// The backend paginates at a fixed 25 and ignores `page_size`, so reading a
  /// single page silently drops everything past the 25th item.
  Future<List<T>> _fetchListAllPages<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final all = <T>[];

    for (var page = 1; page <= kMaxPagesPerFetch; page++) {
      try {
        final response = await _apiClient.get(
          path,
          queryParameters: {...?queryParameters, 'page': page},
        );

        if (response.data == null) {
          throw const ServerException('Empty response from server');
        }

        final data = response.data;
        List listData;
        String? next;

        if (data is Map<String, dynamic> && data.containsKey('results')) {
          listData = (data['results'] as List?) ?? [];
          next = nextPageLink(data);
        } else if (data is List) {
          // Unpaginated endpoint — everything arrived in one response.
          listData = data;
          next = null;
        } else {
          throw const DataParsingException('Unexpected response format');
        }

        all.addAll(
          listData.map((e) => fromJson(e as Map<String, dynamic>)),
        );

        if (next == null) break;
      } on DioException catch (e) {
        throw _handleDioException(e);
      } on FormatException catch (e) {
        throw DataParsingException('Invalid data format: $e');
      } on TypeError catch (e) {
        throw DataParsingException('Data type mismatch: $e');
      } on AppException {
        rethrow;
      } catch (e) {
        throw ServerException('Unexpected error: $e');
      }
    }

    return all;
  }

  // --- Implementation ---

  @override
  /// Returns *every* category, not just [page].
  ///
  /// [page] is the page to start from (callers pass 1). The list is drained to
  /// the end so the Home category grid shows the full catalogue — it used to
  /// render only the first 25 of 40.
  Future<PaginatedResult<Category>> getCategories({int page = 1}) {
    return _fetchAllPages(
      '/api/products/v1/category/', // Updated endpoint
      fromJson: Category.fromJson,
      startPage: page,
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

    // Drained across pages: the Home screen groups these by category, so a
    // single 25-item page meant whole discount sections went missing for
    // categories whose products happened to sort past the cut.
    final products = await _fetchListAllPages(
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

  @override
  Future<Product> getProductById(int id) async {
    try {
      final response = await _apiClient.get('/api/products/v1/$id/');
      if (response.data == null) {
        throw const ServerException('Empty response from server');
      }
      return Product.fromJson(response.data as Map<String, dynamic>);
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
}
