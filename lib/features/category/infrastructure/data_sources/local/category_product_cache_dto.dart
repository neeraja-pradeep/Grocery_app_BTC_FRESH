import '../../models/category_product_dto.dart';

class CategoryProductCacheDto {
  const CategoryProductCacheDto({
    required this.categoryId,
    required this.products,
    required this.lastSyncedAt,
    this.eTag,
    this.lastModified,
    this.count,
    this.next,
    this.previous,
  });

  final String categoryId;
  final List<CategoryProductDto> products;
  final DateTime lastSyncedAt;
  final String? eTag;
  final String? lastModified;
  final int? count;
  final String? next;
  final String? previous;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categoryId': categoryId,
    'products': products.map((dto) => dto.toJson()).toList(),
    'lastSyncedAt': lastSyncedAt.toIso8601String(),
    if (eTag != null) 'eTag': eTag,
    if (lastModified != null) 'lastModified': lastModified,
    if (count != null) 'count': count,
    if (next != null) 'next': next,
    if (previous != null) 'previous': previous,
  };

  factory CategoryProductCacheDto.fromJson(Map<String, dynamic> json) {
    final categoryIdValue = json['categoryId'];
    if (categoryIdValue == null) {
      throw const FormatException('Category product cache missing categoryId.');
    }
    final lastSyncedAtValue = json['lastSyncedAt'];
    if (lastSyncedAtValue is! String) {
      throw const FormatException('Invalid or missing `lastSyncedAt` value.');
    }

    final products = CategoryProductDto.listFromJson(json['products']);

    return CategoryProductCacheDto(
      categoryId: categoryIdValue.toString(),
      products: products,
      lastSyncedAt:
          DateTime.tryParse(lastSyncedAtValue)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal(),
      eTag: json['eTag']?.toString(),
      lastModified: json['lastModified'] as String?,
      count: json['count'] as int?,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
