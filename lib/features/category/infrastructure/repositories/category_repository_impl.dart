import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_schema.dart';
import '../../domain/repositories/category_repository.dart';

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
    Duration cacheTtl = CacheConfig.cacheTTL,
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
    // A truncated cache counts as stale regardless of age, so the screen
    // refreshes it immediately instead of showing a short list for up to a TTL.
    final isStale = _isStale(cache.lastSyncedAt) || _isIncomplete(cache);

    return CategoryRepositoryResult(
      categories: categories,
      isFromCache: true,
      lastSyncedAt: cache.lastSyncedAt,
      isStale: isStale,
      totalCount: cache.count,
      next: cache.next,
      previous: cache.previous,
      lastModified: cache.lastModified,
    );
  }

  /// Syncs categories with conditional request headers for efficiency.
  ///
  /// LOGIC:
  /// ------
  /// 1. Reads lastModified from Hive cache
  /// 2. Sends GET request with If-Modified-Since header (if cache exists)
  /// 3. Handles responses:
  ///    - Server returns 200 (OK): Data changed, save new data + lastModified to Hive
  ///    - Server returns 304 (Not Modified): Data unchanged, just update lastSyncedAt
  /// 4. [forceRemote] = true: Bypasses conditional headers for force refresh
  ///
  /// WHY THIS WORKS:
  /// ---------------
  /// The server compares the If-Modified-Since timestamp with when the
  /// resource was last modified. If the timestamp matches or is newer,
  /// the server returns 304 instead of resending the data.
  @override
  Future<CategoryRepositoryResult> syncCategories({
    bool forceRemote = false,
  }) async {
    final existingCache = _localDataSource.read();

    // A cache written before pagination was followed holds only the first page
    // but carries perfectly valid validators. Replaying them would get a 304
    // and pin the truncated list in place forever, so drop the validators and
    // refetch in full whenever the cache is short of `count`.
    final skipValidators =
        forceRemote || (existingCache != null && _isIncomplete(existingCache));

    final response = await _remoteDataSource.fetchCategories(
      // If forceRemote, send no headers (get full response)
      // Otherwise, use lastModified from Hive for If-Modified-Since
      ifNoneMatch: skipValidators ? null : existingCache?.eTag,
      ifModifiedSince: skipValidators ? null : existingCache?.lastModified,
    );

    // Server returned 304 (Not Modified) - data hasn't changed
    if (response == null) {
      if (existingCache == null) {
        throw const NetworkException(message: 'No category data available.');
      }

      final now = DateTime.now();
      // Only update the lastSyncedAt timestamp, keep the cached data
      await _localDataSource.updateLastSyncedAt(now);

      return CategoryRepositoryResult(
        categories: _mapDtosToDomain(existingCache.categories),
        isFromCache: true,
        lastSyncedAt: now,
        isStale: false,
        totalCount: existingCache.count,
        next: existingCache.next,
        previous: existingCache.previous,
        lastModified: existingCache.lastModified,
      );
    }

    // Server returned 200 (OK) - new data available
    final cacheDto = CategoryCacheDto(
      categories: response.categories,
      lastSyncedAt: response.fetchedAt,
      eTag: response.eTag ?? existingCache?.eTag,
      // Save the NEW lastModified from response for next If-Modified-Since
      lastModified: response.lastModified ?? existingCache?.lastModified,
      count: response.count ?? existingCache?.count,
      // The data source drains every page before returning, so there is no
      // further page. Not `?? existingCache?.next` — that would resurrect a
      // stale page-2 link written before pagination was followed, leaving the
      // cache claiming more data exists when it has all of it.
      next: response.next,
      previous: response.previous,
    );

    await _localDataSource.save(cacheDto);

    return CategoryRepositoryResult(
      categories: _mapDtosToDomain(response.categories),
      isFromCache: false,
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

  /// True when the entry was written by a build that did not follow
  /// pagination, so it holds only the first page.
  ///
  /// This is what makes the pagination fix self-healing for users upgrading
  /// with a truncated cache already on disk.
  bool _isIncomplete(CategoryCacheDto cache) =>
      cache.schemaVersion < CacheSchema.categoryList;

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
