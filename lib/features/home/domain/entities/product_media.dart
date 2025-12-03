import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_media.freezed.dart';

@freezed
class ProductMedia with _$ProductMedia {
  const factory ProductMedia({
    required int id,
    String? imagePath,
    required String imageUrl,
    String? alt,
    String? externalUrl,
    required int productId,
    required DateTime createdAt,
  }) = _ProductMedia;

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    // URL Fixer Logic
    final rawImageUrl = json['image']?.toString() ?? '';
    String finalImageUrl = '';
    if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
      finalImageUrl = 'https://$rawImageUrl';
    } else {
      finalImageUrl = rawImageUrl;
    }

    return ProductMedia(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      imagePath: json['file_path']?.toString(),
      imageUrl: finalImageUrl,
      alt: json['alt']?.toString(),
      externalUrl: json['external_url']?.toString(),
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id'].toString()) ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
