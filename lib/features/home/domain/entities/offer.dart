// features/home/domain/entities/offer.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'offer.freezed.dart';

// --- Place safe parsing helper OUTSIDE the class or in a separate file ---
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
// --------------------------------------------------------------------------

@freezed
class Offer with _$Offer {
  const factory Offer({
    required String id,
    required String name,
    required String title,
    required String subtitle,
    required String imageUrl,
    required double price,
    required double oldPrice,
    required String weight,
    String? category,
  }) = _Offer;

  // Custom factory to handle the actual API response structure (same as Product)
  factory Offer.fromJson(Map<String, dynamic> json) {
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

    final discountedPrice = _parseDouble(json['discounted_price']) ?? 0.0;
    final originalPrice = _parseDouble(json['price']) ?? 0.0;

    return Offer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      title: json['name']?.toString() ?? '', // Use name as title
      subtitle:
          '${_parseDouble(json['weight']) ?? 0}g', // Use weight as subtitle
      imageUrl: imageUrl,
      price: discountedPrice,
      oldPrice: originalPrice,
      weight: '${_parseDouble(json['weight']) ?? 0}g',
      category: null, // Not provided in current API response
    );
  }
}
