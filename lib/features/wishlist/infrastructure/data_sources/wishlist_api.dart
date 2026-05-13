// lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/wishlist_item.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItem>> getWishlist();
  Future<WishlistItem> addToWishlist(String productId);
  Future<void> removeFromWishlist(String wishlistItemId);
}

class WishlistApiImpl implements WishlistRemoteDataSource {
  final ApiClient _apiClient;

  WishlistApiImpl(this._apiClient);

  @override
  Future<List<WishlistItem>> getWishlist() async {
    final response = await _apiClient.get(ApiEndpoints.wishlist);

    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Failed to load wishlist');
    }

    final List responseList;
    if (response.data is List) {
      responseList = response.data as List;
    } else if (response.data is Map &&
        (response.data as Map).containsKey('results')) {
      responseList =
          (response.data as Map<String, dynamic>)['results'] as List;
    } else {
      throw const FormatException('Unexpected wishlist response format');
    }

    // Fetch complete product details for all items in parallel (C6 — was sequential N+1)
    final futures = responseList.map((item) async {
      final wishlistData = item as Map<String, dynamic>;
      final productVariantId = wishlistData['product_variant_id']?.toString();

      if (productVariantId == null) {
        return WishlistItem.fromJson(wishlistData);
      }

      try {
        final productResponse = await _apiClient.get(
          ApiEndpoints.productVariant(productVariantId),
        );

        if (productResponse.statusCode == 200 && productResponse.data != null) {
          return WishlistItem.fromProductVariantResponse(
            wishlistId: wishlistData['id'] ?? 0,
            productData: productResponse.data as Map<String, dynamic>,
          );
        }
        return WishlistItem.fromJson(wishlistData);
      } catch (_) {
        return WishlistItem.fromJson(wishlistData);
      }
    });

    return Future.wait(futures);
  }

  @override
  Future<WishlistItem> addToWishlist(String productId) async {
    final requestData = {
      'product_variant_id': int.tryParse(productId) ?? productId,
    };

    try {
      final response = await _apiClient.post(
        ApiEndpoints.wishlist,
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 && response.data != null) {
        return WishlistItem.fromJson(response.data as Map<String, dynamic>);
      }

      throw FormatException(
        'Failed to add to wishlist - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData.toString()
            : errorData?.toString() ?? 'Bad request';
        throw FormatException('API Error: $errorMessage');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String wishlistItemId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.wishlistById(wishlistItemId),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw const FormatException('Failed to remove from wishlist');
    }
  }
}

final wishlistRemoteDataSourceProvider = Provider<WishlistRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistApiImpl(apiClient);
});
