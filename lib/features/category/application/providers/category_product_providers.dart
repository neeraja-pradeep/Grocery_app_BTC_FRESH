import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';
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
/// 2. CACHE STORAGE (Hive):
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

/// Category products controller - manages product list with 30-second polling
class CategoryProductController
    extends AutoDisposeFamilyNotifier<CategoryProductState, String> {
  static const Duration _pollingInterval = CacheConfig.pollingInterval;

  CategoryProductRepository get _repository =>
      ref.read(categoryProductRepositoryProvider);

  bool _initialized = false;
  bool _disposed = false;
  late String _categoryId;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CategoryProductState build(String categoryId) {
    _categoryId = categoryId;
    _disposed = false;

    // Keep provider alive to prevent disposal when scrolled off-screen
    // This prevents re-fetching and showing loading indicator when scrolling back
    ref.keepAlive();

    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }

    ref.onDispose(_handleDispose);

    // Read cache synchronously to avoid showing loading indicator on rebuild
    // This prevents circular progress when scrolling or when provider rebuilds
    final localDataSource = ref.read(categoryProductLocalDataSourceProvider);
    final cached = localDataSource.read(categoryId);

    developer.log(
      '🔧 BUILD called for category=$categoryId, '
      'initialized=$_initialized, '
      'cacheExists=${cached != null}, '
      'cacheProductCount=${cached?.products.length ?? 0}',
      name: 'CategoryProductController',
      level: 800,
    );

    if (cached != null && cached.products.isNotEmpty) {
      developer.log(
        '✅ Returning CACHED state for category=$categoryId',
        name: 'CategoryProductController',
      );
      return CategoryProductState(
        status: CategoryProductStatus.data,
        products: cached.products.map((dto) => dto.toDomain()).toList(),
        isRefreshing: false,
        lastSyncedAt: cached.lastSyncedAt,
        lastModified: cached.lastModified,
        totalCount: cached.count,
        next: cached.next,
        previous: cached.previous,
      );
    }

    developer.log(
      '⚠️ Returning INITIAL (loading) state for category=$categoryId - NO CACHE',
      name: 'CategoryProductController',
      level: 900,
    );
    return CategoryProductState.initial();
  }

  /// Safe state update that checks if provider is still active
  void _safeSetState(CategoryProductState newState) {
    if (_disposed) return;
    state = newState;
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedProducts(_categoryId);

    if (cached != null) {
      // Don't set isRefreshing here - let _refreshInternal handle it
      // Setting isRefreshing=true here would cause _refreshInternal to return early
      _safeSetState(
        state.copyWith(
          status: cached.hasData
              ? CategoryProductStatus.data
              : CategoryProductStatus.empty,
          products: cached.products,
          lastSyncedAt: cached.lastSyncedAt,
          lastModified: cached.lastModified,
          isRefreshing:
              false, // Will be set to true by _refreshInternal if needed
          totalCount: cached.totalCount,
          next: cached.next,
          previous: cached.previous,
          clearError: true,
        ),
      );
    } else {
      // No cache - show loading state, _refreshInternal will set isRefreshing
      _safeSetState(
        state.copyWith(
          status: CategoryProductStatus.loading,
          isRefreshing: false, // Will be set to true by _refreshInternal
          clearError: true,
        ),
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    }

    // Register for polling - timer will start when feature becomes active
    _registerForPolling();
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

  /// Refresh with loading indicator (for initial load, pull-to-refresh)
  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (_disposed) return;
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    _safeSetState(
      state.copyWith(
        status: hasData
            ? CategoryProductStatus.data
            : CategoryProductStatus.loading,
        isRefreshing: true,
        clearError: true,
      ),
    );

    try {
      final result = await _repository.syncProducts(
        _categoryId,
        forceRemote: forceRemote,
      );

      // Log HTTP status based on data source
      final isFromRemote = result.source == CategoryProductDataSource.remote;
      final httpStatus = isFromRemote ? '200 OK' : '304 Not Modified';
      developer.log(
        'Category $_categoryId: HTTP $httpStatus (${result.products.length} products)',
        name: 'CategoryProductController',
        level: 800,
      );

      _safeSetState(
        state.copyWith(
          status: result.hasData
              ? CategoryProductStatus.data
              : CategoryProductStatus.empty,
          products: result.products,
          lastSyncedAt: result.lastSyncedAt,
          lastModified: result.lastModified,
          isRefreshing: false,
          totalCount: result.totalCount,
          next: result.next,
          previous: result.previous,
          clearError: true,
        ),
      );

      // Show brief refresh indicator
      _showRefreshIndicator();
    } catch (error) {
      developer.log(
        'Category $_categoryId: HTTP Error - $error',
        name: 'CategoryProductController',
        level: 1000,
      );

      final message = _mapError(error);

      if (!hasData) {
        _safeSetState(
          state.copyWith(
            status: CategoryProductStatus.error,
            isRefreshing: false,
            errorMessage: message,
          ),
        );
      } else {
        _safeSetState(
          state.copyWith(isRefreshing: false, errorMessage: message),
        );
      }
    }
  }

  /// Silent background refresh for 30-second polling
  ///
  /// KEY DIFFERENCES FROM _refreshInternal:
  /// - Does NOT show loading indicator (no isRefreshing: true)
  /// - For 304 Not Modified: Does NOT update UI at all (prevents list jumping)
  /// - For 200 OK: Silently updates data without visual feedback
  /// - Errors are logged but don't show to user (keeps existing data)
  ///
  /// This provides smooth UX where users don't see spinners every 30 seconds
  Future<void> _silentRefresh() async {
    if (_disposed) return;
    if (state.isRefreshing) return; // Don't interrupt user-initiated refresh

    try {
      final result = await _repository.syncProducts(
        _categoryId,
        forceRemote: false,
      );

      if (_disposed) return;

      // Check if data came from remote (200 OK) or cache (304 Not Modified)
      final isFromRemote = result.source == CategoryProductDataSource.remote;

      if (isFromRemote) {
        // 200 OK - Server has new data, update UI silently
        developer.log(
          'Category $_categoryId: HTTP 200 OK - Updating UI silently (${result.products.length} products)',
          name: 'CategoryProductController',
          level: 800,
        );

        _safeSetState(
          state.copyWith(
            status: result.hasData
                ? CategoryProductStatus.data
                : CategoryProductStatus.empty,
            products: result.products,
            lastSyncedAt: result.lastSyncedAt,
            lastModified: result.lastModified,
            totalCount: result.totalCount,
            next: result.next,
            previous: result.previous,
            clearError: true,
          ),
        );
      } else {
        // 304 Not Modified - Data unchanged, DO NOT touch UI
        // This prevents list jumping/flickering
        developer.log(
          'Category $_categoryId: HTTP 304 Not Modified - UI unchanged',
          name: 'CategoryProductController',
          level: 500,
        );
        // ✅ Intentionally do nothing - keep existing UI state
      }
    } catch (error) {
      // Silent fail for background polling - don't disturb user
      developer.log(
        'Category $_categoryId: Silent refresh error (ignored) - $error',
        name: 'CategoryProductController',
        level: 900,
      );
      // ✅ Keep existing data on error during background sync
    }
  }

  /// Register for polling with PollingManager
  ///
  /// IMPORTANT: This does NOT start the polling timer immediately!
  /// The timer only starts when PollingManager calls onResume,
  /// which happens when the 'category_products' feature is active.
  ///
  /// PAGE-FOCUSED POLLING:
  /// - Timer starts only when user is viewing category products
  /// - Timer stops when user navigates to Cart, Profile, etc.
  /// - This prevents unnecessary API calls for inactive pages
  void _registerForPolling() {
    // Register with PollingManager - timer will start when feature is active
    PollingManager.instance.registerPoller(
      featureName: 'category_products',
      resourceId: _categoryId,
      onResume: _startPollingTimer,
      onPause: _stopPollingTimer,
    );

    developer.log(
      'Registered polling for category: $_categoryId (waiting for activation)',
      name: 'CategoryProductController',
      level: 700,
    );
  }

  /// Start the polling timer (called by PollingManager when feature becomes active)
  void _startPollingTimer() {
    if (_disposed) return;
    if (_pollingTimer != null) return; // Already running

    developer.log(
      'Starting polling timer for category: $_categoryId (interval: ${_pollingInterval.inSeconds}s)',
      name: 'CategoryProductController',
      level: 700,
    );

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (_disposed) return;
      if (state.isRefreshing) return;

      developer.log(
        'Polling category products for: $_categoryId',
        name: 'CategoryProductController',
        level: 500,
      );

      // Use silent refresh for background polling - no loader, no UI flicker
      await _silentRefresh();
    });
  }

  /// Stop the polling timer (called by PollingManager when feature becomes inactive)
  void _stopPollingTimer() {
    if (_pollingTimer != null) {
      developer.log(
        'Stopping polling timer for category: $_categoryId',
        name: 'CategoryProductController',
        level: 700,
      );
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Show brief refresh indicator after successful poll
  void _showRefreshIndicator() {
    if (_disposed) return;

    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(CacheConfig.refreshIndicatorDuration, () {
      if (_disposed) return;
      _safeSetState(state.copyWith(isRefreshing: false));
    });
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

  void _handleDispose() {
    _disposed = true;

    // Unregister from PollingManager
    PollingManager.instance.unregisterPoller(
      featureName: 'category_products',
      resourceId: _categoryId,
    );

    // Cancel timers
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer = null;
    _initialized = false;

    developer.log(
      'Disposed category products controller for: $_categoryId',
      name: 'CategoryProductController',
      level: 700,
    );
  }
}
