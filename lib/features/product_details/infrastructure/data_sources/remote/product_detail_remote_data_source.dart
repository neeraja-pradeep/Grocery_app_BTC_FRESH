import 'package:grocery_app/core/network/api_client.dart';
import '../../models/product_variant_dto.dart';

/// Response model for product detail with cache headers
class ProductDetailRemoteResponse {
  ProductDetailRemoteResponse({
    required this.productDetail,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final ProductVariantDto productDetail;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
}

/// Remote data source for fetching product details from API
abstract class ProductDetailRemoteDataSource {
  /// Fetch product detail by product ID
  Future<ProductVariantDto> getProductDetail(String productId);

  /// Fetch product detail with conditional headers (supports 304 Not Modified)
  /// Returns null if server responds with 304 (not modified)
  Future<ProductDetailRemoteResponse?> fetchProductDetail({
    required String productId,
    String? ifNoneMatch,
    String? ifModifiedSince,
  });

  /// Fetch product reviews by product ID
  Future<List<ProductVariantReviewDto>> getProductReviews(String productId);

  /// Fetch product variant by variant ID
  Future<ProductVariantDto> getProductVariant(String variantId);

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
  Future<ProductVariantDto> getProductDetail(String productId) async {
    try {
      final response = await _apiClient.get('/products/$productId');
      return ProductVariantDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductDetailRemoteResponse?> fetchProductDetail({
    required String productId,
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

      final response = await _apiClient.get(
        '/api/products/variants/$productId/',
        headers: headers.isNotEmpty ? headers : null,
      );

      // Handle 304 Not Modified
      final statusCode = response.statusCode ?? 200;
      if (statusCode == 304) {
        return null; // Data hasn't changed
      }

      // Extract cache headers from response
      final responseHeaders = response.headers;
      final eTag =
          responseHeaders.value('etag') ?? responseHeaders.value('ETag');
      final lastModified =
          responseHeaders.value('last-modified') ??
          responseHeaders.value('Last-Modified');

      return ProductDetailRemoteResponse(
        productDetail: ProductVariantDto.fromJson(
          response.data as Map<String, dynamic>,
        ),
        fetchedAt: DateTime.now(),
        eTag: eTag,
        lastModified: lastModified,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductVariantReviewDto>> getProductReviews(
    String productId,
  ) async {
    try {
      final response = await _apiClient.get('/products/$productId/reviews');
      final list = response.data as List<dynamic>;
      return list
          .map(
            (e) => ProductVariantReviewDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductVariantDto> getProductVariant(String variantId) async {
    try {
      final response = await _apiClient.get(
        '/api/products/variants/$variantId',
      );
      return ProductVariantDto.fromJson(response.data as Map<String, dynamic>);
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
