import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/category_product_repository.dart';
import '../../infrastructure/data_sources/local/category_product_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_product_remote_data_source.dart';
import '../../infrastructure/repositories/category_product_repository_impl.dart';
import '../states/category_product_state.dart';

/// ============================================================================
/// CATEGORY PRODUCTS LAST-MODIFIED UPDATE SYSTEM
/// ============================================================================
///
/// This implementation uses HTTP conditional requests to efficiently check
/// for updates without downloading unchanged product lists.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD (per category):
///    - Check local Hive cache with categoryId
///    - If empty, fetch from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive with categoryId key
///
/// 2. PERIODIC POLLING (every 30 seconds):
///    - Read If-Modified-Since from Hive for this category
///    - Send conditional GET with If-Modified-Since header
///    - If server returns 304: Keep using cached data, update lastSyncedAt
///    - If server returns 200: New products available, update cache + Last-Modified
///
/// 3. CACHE STORAGE (Hive):
///    - categoryId: The category these products belong to
///    - products: List of product items
///    - lastSyncedAt: When we last checked
///    - lastModified: Server's Last-Modified header (for If-Modified-Since)
///    - eTag: Alternate validation mechanism
///    - count, next, previous: Pagination info
///
/// PER-CATEGORY CACHING:
/// --------------------
/// Each category's products are cached separately with key:
/// 'category_products_{categoryId}'
/// This means viewing multiple categories doesn't cause conflicts.
///
/// POLLING BEHAVIOR:
/// -----------------
/// Each category view has its own polling timer (FamilyNotifier).
/// When you switch to a different category, the old timer is disposed.
/// ============================================================================

final categoryProductLocalDataSourceProvider =
    Provider<CategoryProductLocalDataSource>((ref) {
      return CategoryProductLocalDataSource();
    });

final categoryProductRepositoryProvider = Provider<CategoryProductRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(categoryProductLocalDataSourceProvider);
  final remoteDataSource = CategoryProductRemoteDataSource(apiClient);

  return CategoryProductRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final categoryProductControllerProvider =
    AutoDisposeNotifierProviderFamily<
      CategoryProductController,
      CategoryProductState,
      String
    >(CategoryProductController.new);

class CategoryProductController
    extends AutoDisposeFamilyNotifier<CategoryProductState, String> {
  static const Duration _pollingInterval = Duration(seconds: 30);

  CategoryProductRepository get _repository =>
      ref.read(categoryProductRepositoryProvider);

  bool _initialized = false;
  DateTime? _lastRefreshAttempt;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;
  late String _categoryId;

  @override
  CategoryProductState build(String categoryId) {
    _categoryId = categoryId;
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
      _startPolling();
    }

    ref.onDispose(_handleDispose);

    return CategoryProductState.initial();
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedProducts(_categoryId);

    if (cached != null) {
      state = state.copyWith(
        status: cached.hasData
            ? CategoryProductStatus.data
            : CategoryProductStatus.empty,
        products: cached.products,
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
        status: CategoryProductStatus.loading,
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

  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    state = state.copyWith(
      status: hasData
          ? CategoryProductStatus.data
          : CategoryProductStatus.loading,
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
      resetRefreshEndedAt: true,
      clearError: true,
    );
    _scheduleIndicatorReset();

    try {
      final result = await _repository.syncProducts(
        _categoryId,
        forceRemote: forceRemote,
      );

      state = state.copyWith(
        status: result.hasData
            ? CategoryProductStatus.data
            : CategoryProductStatus.empty,
        products: result.products,
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
          status: CategoryProductStatus.error,
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

  /// Starts periodic polling to check for product updates every 30 seconds.
  ///
  /// How it works:
  /// 1. Every 30 seconds, a refresh is triggered
  /// 2. The repository reads lastModified from Hive for this category
  /// 3. A GET request is sent with If-Modified-Since header
  /// 4. If server responds with 304: UI keeps showing cached products (bandwidth saved!)
  /// 5. If server responds with 200: New products are cached and UI is updated
  ///
  /// Safeguards:
  /// - Skips if already refreshing (prevents overlapping requests)
  /// - Skips if loading initial data
  /// - Per-category: Each category has its own polling timer
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CategoryProductStatus.loading) {
        return;
      }
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

  void _handleDispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer?.cancel();
    _indicatorTimer = null;
    _initialized = false;
    _lastRefreshAttempt = null;
  }
}
