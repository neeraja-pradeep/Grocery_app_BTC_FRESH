import 'package:grocery_app/core/network/api_client.dart';
import '../../models/product_detail_dto.dart';

/// Remote data source for fetching product details from API
abstract class ProductDetailRemoteDataSource {
  /// Fetch product detail by product ID
  Future<ProductDetailDto> getProductDetail(String productId);

  /// Fetch product reviews by product ID
  Future<List<ProductReviewDto>> getProductReviews(String productId);

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId);

  /// Add product to wishlist
  Future<void> addToWishlist(String productId);

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId);
}

/// Implementation using API Client (DIO)
class ProductDetailRemoteDataSourceImpl
    implements ProductDetailRemoteDataSource {
  ProductDetailRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ProductDetailDto> getProductDetail(String productId) async {
    try {
      final response = await _apiClient.get('/products/$productId');
      return ProductDetailDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductReviewDto>> getProductReviews(String productId) async {
    try {
      final response = await _apiClient.get('/products/$productId/reviews');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ProductReviewDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isInWishlist(String productId) async {
    try {
      final response = await _apiClient.get('/wishlist/check/$productId');
      return response.data['inWishlist'] as bool? ?? false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addToWishlist(String productId) async {
    try {
      await _apiClient.post('/wishlist', data: {'productId': productId});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    try {
      await _apiClient.post('/wishlist/remove', data: {'productId': productId});
    } catch (e) {
      rethrow;
    }
  }
}
