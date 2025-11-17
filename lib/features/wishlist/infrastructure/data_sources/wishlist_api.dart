// lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:new_app/features/home/infrastructure/data_sources/remote/home_api.dart';

abstract class WishlistDataSource {
  Future<List<WishlistItem>> getWishlist();
  Future<WishlistItem> addToWishlist(String productId);
  Future<WishlistItem> getWishlistItem(String id);
  Future<WishlistItem> updateWishlistItem(String id, Map<String, dynamic> data);
  Future<void> removeFromWishlist(String id);
}

class WishlistApiImpl implements WishlistDataSource {
  final Dio _dio;

  WishlistApiImpl(this._dio);

  @override
  Future<List<WishlistItem>> getWishlist() async {
    try {
      final response = await _dio.get('/api/order/wishlist/');

      if (response.statusCode == 200 && response.data != null) {
        List responseList;

        if (response.data is List) {
          responseList = response.data as List;
        } else if (response.data is Map &&
            (response.data as Map).containsKey('results')) {
          responseList =
              (response.data as Map<String, dynamic>)['results'] as List;
        } else {
          throw Exception('Unexpected response format');
        }

        return responseList
            .map((item) => WishlistItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to load wishlist');
    } catch (e) {
      throw Exception('Error loading wishlist: $e');
    }
  }

  @override
  Future<WishlistItem> addToWishlist(String productId) async {
    // print('DEBUG: Adding to wishlist - productId: $productId');

    // Based on API documentation, the field should be 'product_variant'
    try {
      final requestData = {
        'product_variant': int.tryParse(productId) ?? productId,
      };

      // print('DEBUG: Trying product_variant - Request data: $requestData');
      // print('DEBUG: Request URL: ${_dio.options.baseUrl}/api/order/wishlist/');
      // print('DEBUG: Request headers: ${_dio.options.headers}');

      final response = await _dio.post(
        '/api/order/wishlist/',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // print('DEBUG: Add to wishlist response status: ${response.statusCode}');
      // print('DEBUG: Add to wishlist response data: ${response.data}');

      if (response.statusCode == 201 && response.data != null) {
        return WishlistItem.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception(
        'Failed to add to wishlist - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      // print('DEBUG: product_variant failed - Error: ${e.message}');

      // Log the detailed error and rethrow since we now know the correct field name
      // print('DEBUG: Error response data: ${e.response?.data}');
      // print('DEBUG: Error response status: ${e.response?.statusCode}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Bad request';
        if (errorData is Map) {
          errorMessage = errorData.toString();
        } else if (errorData is String) {
          errorMessage = errorData;
        }
        throw Exception('API Error: $errorMessage');
      }

      throw Exception('Error adding to wishlist: ${e.message}');
    } catch (e) {
      // print('DEBUG: General error adding to wishlist: $e');
      rethrow;
    }
  }

  @override
  Future<WishlistItem> getWishlistItem(String id) async {
    try {
      final response = await _dio.get('/api/order/wishlist/$id/');

      if (response.statusCode == 200 && response.data != null) {
        return WishlistItem.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to get wishlist item');
    } catch (e) {
      throw Exception('Error getting wishlist item: $e');
    }
  }

  @override
  Future<WishlistItem> updateWishlistItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/api/order/wishlist/$id/', data: data);

      if (response.statusCode == 200 && response.data != null) {
        return WishlistItem.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to update wishlist item');
    } catch (e) {
      throw Exception('Error updating wishlist item: $e');
    }
  }

  @override
  Future<void> removeFromWishlist(String id) async {
    try {
      final response = await _dio.delete('/api/order/wishlist/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to remove from wishlist');
      }
    } catch (e) {
      throw Exception('Error removing from wishlist: $e');
    }
  }
}

final wishlistDataSourceProvider = Provider<WishlistDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return WishlistApiImpl(dio);
});
