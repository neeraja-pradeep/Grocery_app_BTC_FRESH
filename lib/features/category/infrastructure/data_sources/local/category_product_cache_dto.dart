import '../../../../../core/storage/cache_schema.dart';
import '../../models/category_product_dto.dart';

class CategoryProductCacheDto {
  const CategoryProductCacheDto({
    required this.categoryId,
    required this.products,
    required this.lastSyncedAt,
    this.schemaVersion = CacheSchema.categoryProducts,
    this.eTag,
    this.lastModified,
    this.count,
    this.next,
    this.previous,
  });

  final String categoryId;
  final List<CategoryProductDto> products;
  final DateTime lastSyncedAt;

  /// Schema version this entry was written with. Entries predating versioning
  /// read back as [CacheSchema.legacy]. See [CacheSchema].
  final int schemaVersion;
  final String? eTag;
  final String? lastModified;
  final int? count;
  final String? next;
  final String? previous;

  /// Returns a copy with a new [lastSyncedAt], sharing the same product list.
  ///
  /// Used on the 304 Not Modified path, where only the "last checked" time
  /// changes and re-serialising the products would be pure waste.
  CategoryProductCacheDto withLastSyncedAt(DateTime timestamp) =>
      CategoryProductCacheDto(
        categoryId: categoryId,
        products: products,
        lastSyncedAt: timestamp,
        // Carried over, not defaulted — touching the timestamp must not
        // relabel a legacy (truncated) entry as current.
        schemaVersion: schemaVersion,
        eTag: eTag,
        lastModified: lastModified,
        count: count,
        next: next,
        previous: previous,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categoryId': categoryId,
    'products': products.map((dto) => dto.toJson()).toList(),
    'lastSyncedAt': lastSyncedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
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
      schemaVersion: json['schemaVersion'] as int? ?? CacheSchema.legacy,
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
