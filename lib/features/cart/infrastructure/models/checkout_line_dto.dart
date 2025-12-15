import '../../../../core/config/app_config.dart';
import '../../domain/entities/checkout_line.dart';

/// Resolve media URL to CDN
/// Now uses centralized AppConfig
String? _resolveMediaUrl(dynamic mediaEntry) {
  if (mediaEntry == null) return null;

  String? rawUrl;
  String? filePath;

  // Handle media entry as object or string
  if (mediaEntry is Map) {
    rawUrl =
        mediaEntry['image']?.toString() ??
        mediaEntry['external_url']?.toString();
    filePath = mediaEntry['file_path']?.toString();
  } else if (mediaEntry is String) {
    rawUrl = mediaEntry;
  }

  // Try to resolve URL
  if (rawUrl != null && rawUrl.isNotEmpty) {
    return AppConfig.convertToCdnUrl(rawUrl);
  }

  // Try file_path as fallback
  if (filePath != null && filePath.isNotEmpty) {
    return AppConfig.convertToCdnUrl(filePath);
  }

  return null;
}

/// Product variant details DTO
class ProductVariantDetailsDto {
  ProductVariantDetailsDto({
    required this.id,
    required this.sku,
    required this.name,
    required this.productId,
    required this.trackInventory,
    required this.price,
    required this.discountedPrice,
    required this.isSelected,
    required this.isPreorder,
    this.preorderEndDate,
    required this.preorderGlobalThreshold,
    required this.quantityLimitPerCustomer,
    required this.createdAt,
    required this.updatedAt,
    required this.weight,
    required this.status,
    required this.tags,
    this.barCode,
    required this.media,
    required this.currentQuantity,
    required this.currentStockUnit,
    required this.prodDescription,
    required this.productRating,
    required this.warehouseName,
    required this.warehouseId,
  });

  final int id;
  final String sku;
  final String name;
  final int productId;
  final bool trackInventory;
  final String price;
  final String discountedPrice;
  final bool isSelected;
  final bool isPreorder;
  final String? preorderEndDate;
  final int preorderGlobalThreshold;
  final int quantityLimitPerCustomer;
  final String createdAt;
  final String updatedAt;
  final String weight;
  final bool status;
  final String tags;
  final String? barCode;
  final List<dynamic> media;
  final int currentQuantity;
  final String currentStockUnit;
  final String prodDescription;
  final String productRating;
  final String warehouseName;
  final int warehouseId;

  factory ProductVariantDetailsDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantDetailsDto(
      id: json['id'] as int,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productId: json['product_id'] as int,
      trackInventory: json['track_inventory'] as bool? ?? false,
      price: json['price'] as String? ?? '0.00',
      discountedPrice: json['discounted_price'] as String? ?? '0.00',
      isSelected: json['is_selected'] as bool? ?? false,
      isPreorder: json['is_preorder'] as bool? ?? false,
      preorderEndDate: json['preorder_end_date'] as String?,
      preorderGlobalThreshold: json['preorder_global_threshold'] as int? ?? 0,
      quantityLimitPerCustomer:
          json['quantity_limit_per_customer'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      weight: json['weight'] as String? ?? '0.00',
      status: json['status'] as bool? ?? false,
      tags: json['tags'] as String? ?? '',
      barCode: json['bar_code'] as String?,
      media: json['media'] as List<dynamic>? ?? [],
      currentQuantity: json['current_quantity'] as int? ?? 0,
      currentStockUnit: json['current_stock_unit'] as String? ?? '',
      prodDescription: json['prod_description'] as String? ?? '',
      productRating: json['product_rating'] as String? ?? '0.0',
      warehouseName: json['warehouse_name'] as String? ?? '',
      warehouseId: json['warehouse_id'] as int? ?? 0,
    );
  }

  ProductVariantDetails toEntity() {
    return ProductVariantDetails(
      id: id,
      sku: sku,
      name: name,
      productId: productId,
      trackInventory: trackInventory,
      price: price,
      discountedPrice: discountedPrice,
      isSelected: isSelected,
      isPreorder: isPreorder,
      preorderEndDate: preorderEndDate != null
          ? DateTime.tryParse(preorderEndDate!)
          : null,
      preorderGlobalThreshold: preorderGlobalThreshold,
      quantityLimitPerCustomer: quantityLimitPerCustomer,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      weight: weight,
      status: status,
      tags: tags,
      barCode: barCode,
      media: media.map((e) => _resolveMediaUrl(e)).whereType<String>().toList(),
      currentQuantity: currentQuantity,
      currentStockUnit: currentStockUnit,
      prodDescription: prodDescription,
      productRating: productRating,
      warehouseName: warehouseName,
      warehouseId: warehouseId,
    );
  }
}

/// Checkout line DTO
class CheckoutLineDto {
  CheckoutLineDto({
    required this.id,
    required this.checkout,
    required this.productVariantId,
    required this.quantity,
    required this.productVariantDetails,
  });

  final int id;
  final int checkout;
  final int productVariantId;
  final int quantity;
  final ProductVariantDetailsDto productVariantDetails;

  factory CheckoutLineDto.fromJson(Map<String, dynamic> json) {
    return CheckoutLineDto(
      id: json['id'] as int,
      checkout: json['checkout'] as int,
      productVariantId: json['product_variant_id'] as int,
      quantity: json['quantity'] as int,
      productVariantDetails: ProductVariantDetailsDto.fromJson(
        json['product_variant_details'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkout': checkout,
      'product_variant_id': productVariantId,
      'quantity': quantity,
      'product_variant_details': productVariantDetails,
    };
  }

  CheckoutLine toEntity() {
    return CheckoutLine(
      id: id,
      checkout: checkout,
      productVariantId: productVariantId,
      quantity: quantity,
      productVariantDetails: productVariantDetails.toEntity(),
    );
  }
}

/// Checkout lines list response DTO
class CheckoutLinesResponseDto {
  CheckoutLinesResponseDto({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<CheckoutLineDto> results;

  factory CheckoutLinesResponseDto.fromJson(Map<String, dynamic> json) {
    return CheckoutLinesResponseDto(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => CheckoutLineDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CheckoutLinesResponse toEntity() {
    return CheckoutLinesResponse(
      count: count,
      next: next,
      previous: previous,
      results: results.map((dto) => dto.toEntity()).toList(),
    );
  }
}
