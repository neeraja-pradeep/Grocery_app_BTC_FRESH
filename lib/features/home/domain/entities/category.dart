// features/home/domain/entities/category.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required int id,
    required String name,
    required String slug,
    required String description,
    String? backgroundImageUrl,
    String? backgroundImageAlt,
    int? parentId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Category;

  // Custom factory to handle the actual API response structure
  factory Category.fromJson(Map<String, dynamic> json) {
    // Logic to handle URL formatting
    final rawImageUrl = json['background_image_url']?.toString();
    String? finalImageUrl;

    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      // Add https:// if the URL doesn't start with http:// or https://
      if (!rawImageUrl.startsWith('http')) {
        finalImageUrl = 'https://$rawImageUrl';
      } else {
        finalImageUrl = rawImageUrl;
      }
    }

    return Category(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      backgroundImageUrl: finalImageUrl,
      backgroundImageAlt: json['background_image_alt']?.toString(),
      parentId: json['parent_id'] is int
          ? json['parent_id']
          : int.tryParse(json['parent_id']?.toString() ?? ''),
      // Parse dates, defaulting to now() if parsing fails or data is missing
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
