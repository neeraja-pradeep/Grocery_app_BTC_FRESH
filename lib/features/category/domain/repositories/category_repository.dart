import '../entities/category.dart';

enum CategoryDataSource { cache, remote }

class CategoryRepositoryResult {
  const CategoryRepositoryResult({
    required this.categories,
    required this.source,
    required this.lastSyncedAt,
    required this.isStale,
    this.totalCount,
    this.next,
    this.previous,
    this.lastModified,
  });

  final List<Category> categories;
  final CategoryDataSource source;
  final DateTime? lastSyncedAt;
  final bool isStale;
  final int? totalCount;
  final String? next;
  final String? previous;
  final String? lastModified;

  bool get hasData => categories.isNotEmpty;
}

abstract class CategoryRepository {
  Duration get cacheTtl;

  Future<CategoryRepositoryResult?> getCachedCategories();

  Future<CategoryRepositoryResult> syncCategories({bool forceRemote = false});
}
