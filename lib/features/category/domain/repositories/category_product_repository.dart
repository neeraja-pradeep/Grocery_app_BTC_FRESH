import '../entities/category_product.dart';

enum CategoryProductDataSource { cache, remote }

class CategoryProductRepositoryResult {
  const CategoryProductRepositoryResult({
    required this.products,
    required this.source,
    required this.lastSyncedAt,
    required this.isStale,
    this.totalCount,
    this.next,
    this.previous,
    this.eTag,
    this.lastModified,
  });

  final List<CategoryProduct> products;
  final CategoryProductDataSource source;
  final DateTime? lastSyncedAt;
  final bool isStale;
  final int? totalCount;
  final String? next;
  final String? previous;
  final String? eTag;
  final String? lastModified;

  bool get hasData => products.isNotEmpty;
}

abstract class CategoryProductRepository {
  Duration get cacheTtl;

  Future<CategoryProductRepositoryResult?> getCachedProducts(String categoryId);

  Future<CategoryProductRepositoryResult> syncProducts(
    String categoryId, {
    bool forceRemote = false,
  });
}
