import '../../../../core/network/endpoints.dart';

import '../../domain/entities/category.dart';

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.imageAlt,
    this.parentId,
    this.slug,
  });

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final String? imageAlt;
  final int? parentId;
  final String? slug;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['categoryId'] ?? json['uuid'];
    if (rawId == null) {
      throw const FormatException('Category payload missing `id`.');
    }

    final rawTitle = json['name'] ?? json['title'] ?? json['label'];
    if (rawTitle == null) {
      throw const FormatException('Category payload missing `title`.');
    }

    final rawImageUrl =
        json['background_image_url'] ??
        json['image'] ??
        json['imageUrl'] ??
        json['thumbnail'] ??
        json['icon'];
    final rawImagePath = json['background_image_path']?.toString();
    final resolvedImageUrl = _resolveImageUrl(
      rawImageUrl?.toString(),
      rawImagePath,
    );

    final parentValue = json['parent_id'];
    int? parentId;
    if (parentValue is int) {
      parentId = parentValue;
    } else if (parentValue is String) {
      parentId = int.tryParse(parentValue);
    }

    final descriptionPlain = json['description_plaintext'];
    final descriptionRaw = descriptionPlain ?? json['description'];

    return CategoryDto(
      id: '$rawId',
      title: '$rawTitle',
      description: descriptionRaw?.toString(),
      imageUrl: resolvedImageUrl,
      imagePath: resolvedImageUrl ?? rawImagePath,
      imageAlt: json['background_image_alt']?.toString(),
      parentId: parentId,
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (imagePath != null) 'imagePath': imagePath,
    if (imageAlt != null) 'imageAlt': imageAlt,
    if (parentId != null) 'parentId': parentId,
    if (slug != null) 'slug': slug,
  };

  Category toDomain() => Category(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    imagePath: imagePath,
    imageAlt: imageAlt,
    parentId: parentId,
    slug: slug,
  );

  static List<CategoryDto> listFromJson(dynamic data) {
    if (data is List) {
      return data
          .whereType<dynamic>()
          .map<Map<String, dynamic>>((dynamic item) {
            if (item is Map<String, dynamic>) return item;
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            throw const FormatException('Invalid category list item.');
          })
          .map(CategoryDto.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        return listFromJson(data['results']);
      }
      if (data['data'] is List) {
        return listFromJson(data['data']);
      }
      if (data['items'] is List) {
        return listFromJson(data['items']);
      }
    }

    throw const FormatException('Unexpected categories payload shape.');
  }
}

String? _resolveImageUrl(String? imageUrl, String? imagePath) {
  String? normalized = imageUrl;
  if (normalized != null && normalized.isNotEmpty) {
    if (!normalized.startsWith('http')) {
      normalized = 'https://$normalized';
    }
    return normalized;
  }

  if (imagePath != null && imagePath.isNotEmpty) {
    final base = ApiEndpoints.baseUrl;
    if (base.endsWith('/') && imagePath.startsWith('/')) {
      return '${base.substring(0, base.length - 1)}$imagePath';
    }
    return '$base$imagePath';
  }

  return null;
}
