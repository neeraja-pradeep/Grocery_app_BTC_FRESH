// lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:new_app/features/home/infrastructure/data_sources/remote/home_api.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItem>> getWishlist();
  Future<WishlistItem> addToWishlist(String productId);
  Future<void> removeFromWishlist(String wishlistItemId);
}

class WishlistApiImpl implements WishlistRemoteDataSource {
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
    try {
      final requestData = {
        'product_variant': int.tryParse(productId) ?? productId,
      };

      final response = await _dio.post(
        '/api/order/wishlist/',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 && response.data != null) {
        return WishlistItem.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception(
        'Failed to add to wishlist - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
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
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String wishlistItemId) async {
    try {
      final response = await _dio.delete(
        '/api/order/wishlist/$wishlistItemId/',
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to remove from wishlist');
      }
    } catch (e) {
      throw Exception('Error removing from wishlist: $e');
    }
  }
}

final wishlistRemoteDataSourceProvider = Provider<WishlistRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return WishlistApiImpl(dio);
});
