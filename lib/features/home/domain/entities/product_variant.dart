import 'package:freezed_annotation/freezed_annotation.dart';
import 'product_media.dart';

part 'product_variant.freezed.dart';

// Helper for safe parsing (placed outside or in a utils file)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@freezed
class ProductVariant with _$ProductVariant {
  // Private constructor is required for custom getters/methods
  const ProductVariant._();

  const factory ProductVariant({
    required int id,
    required String name,
    required int productId,
    required String sku,
    required double price,
    double? discountedPrice,
    String? stockUnit,
    required String currentQuantity,
    required bool status,
    required List<ProductMedia> media,
    String? productDescription,
    double? productRating,
    int? quantityLimitPerCustomer,
    required bool isPreorder,
    DateTime? preorderEndDate,
    String? tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      sku: json['sku']?.toString() ?? '',

      // Handle "26312280.0" string to double
      price: _parseDouble(json['price']) ?? 0.0,
      discountedPrice: _parseDouble(json['discounted_price']),

      stockUnit:
          json['stock_unit']?.toString() ??
          json['unit']?.toString() ??
          json['weight']?.toString() ??
          json['size']?.toString(),
      currentQuantity: json['current_quantity']?.toString() ?? '0',
      status: json['status'] == true, // Ensures boolean
      // Parse nested List<ProductMedia>
      media:
          (json['media'] as List<dynamic>?)
              ?.map((e) => ProductMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      productDescription: json['prod_description']
          ?.toString(), // Note: API key is prod_description
      // Handle "." or "-9.3"
      productRating: _parseDouble(json['product_rating']),

      quantityLimitPerCustomer: int.tryParse(
        json['quantity_limit_per_customer']?.toString() ?? '',
      ),
      isPreorder: json['is_preorder'] == true,
      preorderEndDate: DateTime.tryParse(
        json['preorder_end_date']?.toString() ?? '',
      ),
      tags: json['tags']?.toString(),

      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // --- Computed Properties ---

  bool get hasDiscount {
    return discountedPrice != null &&
        discountedPrice! < price &&
        discountedPrice! > 0;
  }

  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return (((price - discountedPrice!) / price) * 100);
  }

  String get displayPrice {
    // Example logic: if discounted, show that, else show regular price
    // You can adjust formatting (e.g., add currency symbol) here
    final val = hasDiscount ? discountedPrice! : price;
    return val.toStringAsFixed(2);
  }
}
