import '../../models/product_variant_dto.dart';

/// Cache DTO for storing product detail with HTTP cache headers
class ProductDetailCacheDto {
  ProductDetailCacheDto({
    required this.productDetail,
    required this.lastSyncedAt,
    this.eTag,
    this.lastModified,
  });

  final ProductVariantDto productDetail;
  final DateTime lastSyncedAt;
  final String? eTag;
  final String? lastModified;

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() => {
    'product_detail': productDetail.toJson(),
    'last_synced_at': lastSyncedAt.toIso8601String(),
    'etag': eTag,
    'last_modified': lastModified,
  };

  /// Create from JSON
  factory ProductDetailCacheDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailCacheDto(
      productDetail: ProductVariantDto.fromJson(
        json['product_detail'] as Map<String, dynamic>,
      ),
      lastSyncedAt: DateTime.parse(json['last_synced_at'] as String),
      eTag: json['etag'] as String?,
      lastModified: json['last_modified'] as String?,
    );
  }

  /// Copy with method for immutable updates
  ProductDetailCacheDto copyWith({
    ProductVariantDto? productDetail,
    DateTime? lastSyncedAt,
    String? eTag,
    String? lastModified,
  }) {
    return ProductDetailCacheDto(
      productDetail: productDetail ?? this.productDetail,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
