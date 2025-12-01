// lib/features/home/domain/entities/banner.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner.freezed.dart';

@freezed
class Banner with _$Banner {
  // Private constructor for custom methods
  const Banner._();

  const factory Banner({
    required int id,
    required String name,
    String? descriptionPlaintext,
    required String imageUrl,
    int? categoryId,
    int? productId,
    int? productVariantId,
  }) = _Banner;

  factory Banner.fromJson(Map<String, dynamic> json) {
    // Logic to handle URL formatting (ensure https)
    final rawImageUrl = json['image']?.toString() ?? '';
    String finalImageUrl = '';

    if (rawImageUrl.isNotEmpty) {
      if (!rawImageUrl.startsWith('http')) {
        finalImageUrl = 'https://$rawImageUrl';
      } else {
        finalImageUrl = rawImageUrl;
      }
    }

    // Helper to parse nullable integers safely
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return value == 0 ? null : value;
      } // Treat 0 as null if API returns 0 for empty
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Banner(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      descriptionPlaintext: json['description_plaintext']?.toString(),
      imageUrl: finalImageUrl,

      // Map API keys to Domain fields
      // The API returns 0 or null for empty relationships, we handle both.
      categoryId: parseInt(json['category']),
      productId: parseInt(json['product']),
      productVariantId: parseInt(json['product_variant']),
    );
  }

  // --- Computed Properties / Logic ---

  /// Determines the navigation target type.
  /// Returns 'category', 'product', 'variant', or null if no link exists.
  String? get targetType {
    if (productVariantId != null && productVariantId != 0) return 'variant';
    if (productId != null && productId != 0) return 'product';
    if (categoryId != null && categoryId != 0) return 'category';
    return null;
  }

  /// Returns the ID of the target entity to navigate to.
  int? get targetId {
    return productVariantId ?? productId ?? categoryId;
  }
}
