// features/home/domain/entities/product.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

// --- Place safe parsing helpers OUTSIDE the class or in a separate file ---
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// int? _parseInt(dynamic value) {
//   if (value == null) return null;
//   if (value is int) return value;
//   if (value is double) return value.toInt();
//   if (value is String) return int.tryParse(value);
//   return null;
// }
// --------------------------------------------------------------------------

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    required double mrp,
    required String imageUrl,
    required String unitLabel,
    required int discountPct,
    double? rating,
  }) = _Product;

  // Custom factory to handle the actual API response structure
  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract image URL from media array
    String imageUrl = '';
    if (json['media'] is List && (json['media'] as List).isNotEmpty) {
      final media = (json['media'] as List).first;
      final rawImageUrl = media['image']?.toString() ?? '';
      // Add https:// if the URL doesn't start with http:// or https://
      if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
        imageUrl = 'https://$rawImageUrl';
      } else {
        imageUrl = rawImageUrl;
      }
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price:
          _parseDouble(json['discounted_price']) ??
          _parseDouble(json['price']) ??
          0.0,
      mrp: _parseDouble(json['price']) ?? 0.0,
      imageUrl: imageUrl,
      unitLabel: '${_parseDouble(json['weight']) ?? 0}g',
      discountPct: _calculateDiscountPct(
        _parseDouble(json['price']) ?? 0.0,
        _parseDouble(json['discounted_price']) ?? 0.0,
      ),
      rating: _parseDouble(json['product_rating']),
    );
  }

  static int _calculateDiscountPct(
    double originalPrice,
    double discountedPrice,
  ) {
    if (originalPrice <= 0 || discountedPrice >= originalPrice) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }
}
