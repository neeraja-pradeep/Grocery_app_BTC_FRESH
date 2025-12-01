import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/category_repository.dart';
import '../../infrastructure/data_sources/local/category_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_remote_data_source.dart';
import '../../infrastructure/repositories/category_repository_impl.dart';
import '../states/category_state.dart';

/// ============================================================================
/// CATEGORY LAST-MODIFIED UPDATE SYSTEM
/// ============================================================================
///
/// This implementation uses HTTP conditional requests to efficiently check
/// for updates without downloading unchanged data.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD:
///    - Check local Hive cache
///    - If empty, fetch from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive
///
/// 2. CACHE STORAGE (Hive):
///    - categories: List of category items
///    - lastSyncedAt: When we last checked
///    - lastModified: Server's Last-Modified header (for If-Modified-Since)
///    - eTag: Alternate validation (not used but preserved)
///    - count, next, previous: Pagination info
///
/// KEY OPTIMIZATION:
/// -----------------
/// 304 responses (Not Modified) avoid re-downloading unchanged data,
/// saving bandwidth while keeping the UI always current when needed.
/// ============================================================================

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  return CategoryLocalDataSource();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final remoteDataSource = CategoryRemoteDataSource(apiClient);

  return CategoryRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);

class CategoryController extends Notifier<CategoryState> {
  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  bool _initialized = false;

  @override
  CategoryState build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }
    ref.onDispose(_disposeController);
    return CategoryState.initial();
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedCategories();

    if (cached != null) {
      state = state.copyWith(
        status: cached.hasData ? CategoryStatus.data : CategoryStatus.empty,
        categories: cached.categories,
        lastSyncedAt: cached.lastSyncedAt,
        lastModified: cached.lastModified,
        isRefreshing: cached.isStale,
        totalCount: cached.totalCount,
        next: cached.next,
        previous: cached.previous,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: CategoryStatus.loading,
        isRefreshing: true,
        clearError: true,
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> refresh({bool force = false}) async {
    await _refreshInternal(forceRemote: force);
  }

  Future<void> refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    if (lastSyncedAt == null ||
        now.difference(lastSyncedAt) >= _repository.cacheTtl) {
      await refresh();
    }
  }

  /// Syncs categories with the server, using If-Modified-Since for efficiency.
  ///
  /// If [forceRemote] is true, it bypasses conditional headers and always
  /// fetches fresh data from the server.
  ///
  /// The repository will:
  /// - Pass If-Modified-Since header with the lastModified value from Hive
  /// - Return null if server responds with 304 (Not Modified)
  /// - Return new data if server responds with 200 (OK)
  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    state = state.copyWith(
      status: hasData ? CategoryStatus.data : CategoryStatus.loading,
      isRefreshing: true,
      clearError: true,
    );

    try {
      final result = await _repository.syncCategories(forceRemote: forceRemote);

      state = state.copyWith(
        status: result.hasData ? CategoryStatus.data : CategoryStatus.empty,
        categories: result.categories,
        lastSyncedAt: result.lastSyncedAt,
        lastModified: result.lastModified,
        isRefreshing: false,
        totalCount: result.totalCount,
        next: result.next,
        previous: result.previous,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      if (!hasData) {
        state = state.copyWith(
          status: CategoryStatus.error,
          isRefreshing: false,
          errorMessage: message,
        );
      } else {
        state = state.copyWith(isRefreshing: false, errorMessage: message);
      }
    }
  }

  String _mapError(Object error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  void _disposeController() {
    _initialized = false;
  }
}
