import 'dart:async';

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
/// 2. PERIODIC POLLING (every 30 seconds):
///    - Read If-Modified-Since from Hive
///    - Send conditional GET with If-Modified-Since header
///    - If server returns 304: Keep using cached data, update lastSyncedAt
///    - If server returns 200: New data available, update cache + Last-Modified
///
/// 3. CACHE STORAGE (Hive):
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
  static const Duration _pollingInterval = Duration(seconds: 30);

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  bool _initialized = false;
  DateTime? _lastRefreshAttempt;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CategoryState build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
      _startPolling();
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
        refreshStartedAt: cached.isStale
            ? DateTime.now()
            : state.refreshStartedAt,
        refreshEndedAt: cached.isStale ? null : DateTime.now(),
        resetRefreshEndedAt: cached.isStale,
        totalCount: cached.totalCount,
        next: cached.next,
        previous: cached.previous,
        clearError: true,
      );
      _scheduleIndicatorReset();
    } else {
      state = state.copyWith(
        status: CategoryStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
        resetRefreshEndedAt: true,
        clearError: true,
      );
      _scheduleIndicatorReset();
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      state = state.copyWith(isRefreshing: false, resetRefreshStartedAt: true);
    }
  }

  Future<void> refresh({bool force = false}) async {
    await _refreshInternal(forceRemote: force);
  }

  Future<void> refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    final recentlyRequested =
        _lastRefreshAttempt != null &&
        now.difference(_lastRefreshAttempt!) < _pollingInterval;
    if (recentlyRequested) return;

    if (lastSyncedAt == null ||
        now.difference(lastSyncedAt) >= _repository.cacheTtl) {
      _lastRefreshAttempt = now;
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
      refreshStartedAt: DateTime.now(),
      resetRefreshEndedAt: true,
      clearError: true,
    );
    _scheduleIndicatorReset();

    try {
      final result = await _repository.syncCategories(forceRemote: forceRemote);

      state = state.copyWith(
        status: result.hasData ? CategoryStatus.data : CategoryStatus.empty,
        categories: result.categories,
        lastSyncedAt: result.lastSyncedAt,
        lastModified: result.lastModified,
        isRefreshing: false,
        resetRefreshStartedAt: true,
        refreshEndedAt: DateTime.now(),
        resetRefreshEndedAt: false,
        totalCount: result.totalCount,
        next: result.next,
        previous: result.previous,
        clearError: true,
      );
      _scheduleIndicatorReset();
      _lastRefreshAttempt = DateTime.now();
    } catch (error) {
      final message = _mapError(error);

      if (!hasData) {
        state = state.copyWith(
          status: CategoryStatus.error,
          isRefreshing: false,
          resetRefreshStartedAt: true,
          refreshEndedAt: DateTime.now(),
          resetRefreshEndedAt: false,
          errorMessage: message,
        );
      } else {
        state = state.copyWith(
          isRefreshing: false,
          resetRefreshStartedAt: true,
          refreshEndedAt: DateTime.now(),
          resetRefreshEndedAt: false,
          errorMessage: message,
        );
      }
      _scheduleIndicatorReset();
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

  /// Starts periodic polling to check for updates every 30 seconds.
  ///
  /// How it works:
  /// 1. Every 30 seconds, a refresh is triggered
  /// 2. The repository reads lastModified from Hive
  /// 3. A GET request is sent with If-Modified-Since header
  /// 4. If server responds with 304: UI keeps showing cached data (bandwidth saved!)
  /// 5. If server responds with 200: New data is cached and UI is updated
  ///
  /// Safeguards:
  /// - Skips if already refreshing (prevents overlapping requests)
  /// - Skips if loading initial data
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CategoryStatus.loading) return;
      unawaited(refresh());
    });
  }

  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  void _disposeController() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer?.cancel();
    _indicatorTimer = null;
    _initialized = false;
    _lastRefreshAttempt = null;
  }
}
