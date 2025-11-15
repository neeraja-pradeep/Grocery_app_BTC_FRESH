import 'package:grocery_app/features/category/domain/repositories/category_repository.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/category.dart';
import '../data_sources/local/category_cache_dto.dart';
import '../data_sources/local/category_local_data_source.dart';
import '../data_sources/remote/category_remote_data_source.dart';
import '../models/category_dto.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({
    required CategoryLocalDataSource localDataSource,
    required CategoryRemoteDataSource remoteDataSource,
    Duration cacheTtl = const Duration(minutes: 10),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _cacheTtl = cacheTtl;

  final CategoryLocalDataSource _localDataSource;
  final CategoryRemoteDataSource _remoteDataSource;
  final Duration _cacheTtl;

  @override
  Duration get cacheTtl => _cacheTtl;

  @override
  Future<CategoryRepositoryResult?> getCachedCategories() async {
    final cache = _localDataSource.read();
    if (cache == null) return null;

    final categories = _mapDtosToDomain(cache.categories);
    final isStale = _isStale(cache.lastSyncedAt);

    return CategoryRepositoryResult(
      categories: categories,
      source: CategoryDataSource.cache,
      lastSyncedAt: cache.lastSyncedAt,
      isStale: isStale,
      totalCount: cache.count,
      next: cache.next,
      previous: cache.previous,
      lastModified: cache.lastModified,
    );
  }

  @override
  Future<CategoryRepositoryResult> syncCategories({
    bool forceRemote = false,
  }) async {
    final existingCache = _localDataSource.read();

    final response = await _remoteDataSource.fetchCategories(
      ifNoneMatch: forceRemote ? null : existingCache?.eTag,
      ifModifiedSince: forceRemote ? null : existingCache?.lastModified,
    );

    if (response == null) {
      if (existingCache == null) {
        throw const NetworkException(message: 'No category data available.');
      }

      final now = DateTime.now();
      await _localDataSource.updateLastSyncedAt(now);

      return CategoryRepositoryResult(
        categories: _mapDtosToDomain(existingCache.categories),
        source: CategoryDataSource.cache,
        lastSyncedAt: now,
        isStale: false,
        totalCount: existingCache.count,
        next: existingCache.next,
        previous: existingCache.previous,
        lastModified: existingCache.lastModified,
      );
    }

    final cacheDto = CategoryCacheDto(
      categories: response.categories,
      lastSyncedAt: response.fetchedAt,
      eTag: response.eTag ?? existingCache?.eTag,
      lastModified: response.lastModified ?? existingCache?.lastModified,
      count: response.count ?? existingCache?.count,
      next: response.next ?? existingCache?.next,
      previous: response.previous ?? existingCache?.previous,
    );

    await _localDataSource.save(cacheDto);

    return CategoryRepositoryResult(
      categories: _mapDtosToDomain(response.categories),
      source: CategoryDataSource.remote,
      lastSyncedAt: response.fetchedAt,
      isStale: false,
      totalCount: response.count,
      next: response.next,
      previous: response.previous,
      lastModified: response.lastModified ?? existingCache?.lastModified,
    );
  }

  bool _isStale(DateTime lastSyncedAt) {
    final now = DateTime.now();
    return now.difference(lastSyncedAt) >= _cacheTtl;
  }

  List<Category> _mapDtosToDomain(List<CategoryDto> dtos) {
    final categories = dtos.map((dto) => dto.toDomain()).toList();
    categories.sort((a, b) {
      final aId = int.tryParse(a.id);
      final bId = int.tryParse(b.id);
      if (aId != null && bId != null) {
        return aId.compareTo(bId);
      }
      if (aId != null) return -1;
      if (bId != null) return 1;
      return a.id.compareTo(b.id);
    });
    return categories;
  }
}
