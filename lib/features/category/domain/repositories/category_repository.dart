import '../entities/category.dart';

/// Indicates where category data was retrieved from (cache or remote API).
///
/// Used to determine if a result came from local Hive storage or fresh from the API.
/// Helps UI decide whether to show loading indicators or cached data indicators.
enum CategoryDataSource {
  /// Data retrieved from local Hive storage
  cache,

  /// Data retrieved from remote API
  remote,
}

/// Result of a category repository operation.
///
/// Contains the fetched categories, metadata about when they were synced,
/// and pagination information for loading more data.
///
/// Example:
/// ```dart
/// final result = await categoryRepository.syncCategories();
/// if (result.hasData) {
///   print('${result.categories.length} categories loaded');
/// }
/// if (result.isStale) {
///   print('Data is older than TTL, should refresh');
/// }
/// ```
class CategoryRepositoryResult {
  /// Creates a new [CategoryRepositoryResult].
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

  /// List of categories returned from cache or API.
  final List<Category> categories;

  /// Where these categories came from (cache or remote).
  final CategoryDataSource source;

  /// When these categories were last synced with the server.
  ///
  /// Used to determine if data is stale and needs refresh.
  final DateTime? lastSyncedAt;

  /// Whether this data is older than the cache TTL.
  ///
  /// If true, a fresh sync should be triggered soon to get latest data.
  final bool isStale;

  /// Total count of categories available on the server.
  ///
  /// Useful for showing "X categories available" to users.
  /// May be null if API doesn't support pagination.
  final int? totalCount;

  /// URL to fetch the next page of categories.
  ///
  /// Present when more data is available beyond current page.
  /// Use this to implement infinite scroll or pagination.
  final String? next;

  /// URL to fetch the previous page of categories.
  ///
  /// Present in paginated results with multiple pages.
  final String? previous;

  /// Last-Modified header from the API response.
  ///
  /// Stored for If-Modified-Since conditional request headers.
  /// Allows skipping download on next sync if data unchanged (304 Not Modified).
  final String? lastModified;

  /// Whether the result contains any categories.
  bool get hasData => categories.isNotEmpty;
}

/// Repository interface for category data operations.
///
/// Defines the contract for fetching categories from both local cache (Hive)
/// and remote API sources. Implementations handle:
/// - Local caching with Hive
/// - HTTP conditional requests (If-Modified-Since headers)
/// - TTL-based cache invalidation
/// - Pagination support
///
/// Example:
/// ```dart
/// final result = await categoryRepository.syncCategories();
/// final categories = result.categories;
///
/// // Refresh with fresh data
/// final fresh = await categoryRepository.syncCategories(forceRemote: true);
/// ```
abstract class CategoryRepository {
  /// Time-to-live duration for cached category data.
  ///
  /// After this duration, cached data is considered stale and should be refreshed.
  /// Typically 1 hour to balance freshness with bandwidth efficiency.
  Duration get cacheTtl;

  /// Retrieves cached categories from local storage without network requests.
  ///
  /// Returns null if no cached data exists.
  /// Returns data regardless of whether it's marked as stale.
  ///
  /// Use this for quick offline access. Check [CategoryRepositoryResult.isStale]
  /// to determine if data should be refreshed.
  ///
  /// Throws: May throw exception if Hive storage is corrupted.
  Future<CategoryRepositoryResult?> getCachedCategories();

  /// Syncs categories with the server using efficient conditional requests.
  ///
  /// If [forceRemote] is false (default):
  /// - Returns cached data if available and fresh (within TTL)
  /// - Sends If-Modified-Since header if cached data exists
  /// - Server responds with 304 to skip downloading unchanged data
  /// - Only downloads if data changed (200 OK from API)
  ///
  /// If [forceRemote] is true:
  /// - Bypasses cache and fetches fresh data unconditionally
  /// - Always returns latest data from API
  ///
  /// Returns: Latest categories from cache or server
  /// Throws: NetworkException if sync fails
  ///
  /// Example:
  /// ```dart
  /// // Get fresh data
  /// final result = await categoryRepository.syncCategories();
  ///
  /// // Force bypass cache
  /// final fresh = await categoryRepository.syncCategories(forceRemote: true);
  /// ```
  Future<CategoryRepositoryResult> syncCategories({bool forceRemote = false});
}
