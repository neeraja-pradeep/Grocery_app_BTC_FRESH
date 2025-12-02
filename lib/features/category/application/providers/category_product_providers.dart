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

    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }

    ref.onDispose(_handleDispose);

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
      _safeSetState(
        state.copyWith(
          status: cached.hasData
              ? CategoryProductStatus.data
              : CategoryProductStatus.empty,
          products: cached.products,
          lastSyncedAt: cached.lastSyncedAt,
          lastModified: cached.lastModified,
          isRefreshing: cached.isStale,
          totalCount: cached.totalCount,
          next: cached.next,
          previous: cached.previous,
          clearError: true,
        ),
      );
    } else {
      _safeSetState(
        state.copyWith(
          status: CategoryProductStatus.loading,
          isRefreshing: true,
          clearError: true,
        ),
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      _safeSetState(state.copyWith(isRefreshing: false));
    }

    // Start polling after initial load
    _startPolling();
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

  /// Start automatic polling every 30 seconds
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (_disposed) return;
      if (state.isRefreshing) return;

      developer.log(
        'Polling category products for: $_categoryId',
        name: 'CategoryProductController',
        level: 500,
      );

      await _refreshInternal(forceRemote: false);
    });

    // Register with PollingManager for screen-aware polling
    PollingManager.instance.registerPoller(
      featureName: 'category_products',
      resourceId: _categoryId,
      onResume: _resumePolling,
      onPause: _pausePolling,
    );

    developer.log(
      'Started polling for category: $_categoryId (interval: ${_pollingInterval.inSeconds}s)',
      name: 'CategoryProductController',
      level: 700,
    );
  }

  /// Resume polling when user navigates back to category screen
  void _resumePolling() {
    if (_pollingTimer == null && !_disposed) {
      developer.log(
        'Resuming polling for category: $_categoryId',
        name: 'CategoryProductController',
        level: 700,
      );
      _startPolling();
    }
  }

  /// Pause polling when user navigates away from category screen
  void _pausePolling() {
    if (_pollingTimer != null) {
      developer.log(
        'Pausing polling for category: $_categoryId',
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
