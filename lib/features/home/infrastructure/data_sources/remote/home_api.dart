// lib/features/home/infrastructure/data_sources/remote/home_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
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

  Future<PaginatedResult<T>> _fetchPaginated<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    final data = response.data as Map<String, dynamic>;

    return PaginatedResult(
      count: data['count'] ?? 0,
      next: data['next'],
      previous: data['previous'],
      results: (data['results'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<T>> _fetchList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);

    List listData;
    if (response.data is Map && response.data.containsKey('results')) {
      listData = response.data['results'];
    } else {
      listData = response.data as List;
    }
    return listData.map((e) => fromJson(e as Map<String, dynamic>)).toList();
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
    // Placeholder implementation
    // If API returns 404 or empty, return null.
    try {
      // final response = await _dio.get('/api/users/address/selected/');
      // return UserAddress.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProductVariant>> getBestDeals({int limit = 10}) async {
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
