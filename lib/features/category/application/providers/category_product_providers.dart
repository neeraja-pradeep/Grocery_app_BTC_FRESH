import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/category_product.dart';
import '../../domain/repositories/category_product_repository.dart';
import '../../infrastructure/providers/category_infrastructure_providers.dart';
import '../states/category_product_state.dart';

// H1 fix: NotifierProviderFamily (not AutoDispose) — keepAlive behaviour is
// the intent; declaring AutoDispose then calling ref.keepAlive() was contradictory.
final categoryProductControllerProvider =
    NotifierProviderFamily<CategoryProductController, CategoryProductState,
        String>(CategoryProductController.new);

class CategoryProductController
    extends FamilyNotifier<CategoryProductState, String> {
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

    // Return initial loading state; _loadInitial will populate from cache or API.
    return CategoryProductState.initial();
  }

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
          isRefreshing: false,
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
          isRefreshing: false,
          clearError: true,
        ),
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    }

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

    const retryDelays = [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];

    Object? lastError;
    for (var attempt = 0; attempt <= 3; attempt++) {
      try {
        final result = await _repository.syncProducts(
          _categoryId,
          forceRemote: forceRemote,
        );

        Logger.debug(
          'Category $_categoryId: ${result.isFromCache ? "304 Not Modified" : "200 OK"} '
          '(${result.products.length} products)',
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
        _showRefreshIndicator();
        return;
      } catch (error) {
        lastError = error;
        if (error is NetworkException &&
            error.statusCode != null &&
            error.statusCode! >= 400 &&
            error.statusCode! < 500) {
          break;
        }
        if (attempt < 3) {
          await Future.delayed(retryDelays[attempt]);
        }
      }
    }

    Logger.error('Category $_categoryId load failed', error: lastError);
    final message = _mapError(lastError!);
    if (!hasData) {
      _safeSetState(
        state.copyWith(
          status: CategoryProductStatus.error,
          isRefreshing: false,
          errorMessage: message,
        ),
      );
    } else {
      _safeSetState(state.copyWith(isRefreshing: false, errorMessage: message));
    }
  }

  Future<void> _silentRefresh() async {
    if (_disposed) return;
    if (state.isRefreshing) return;

    try {
      final result = await _repository.syncProducts(
        _categoryId,
        forceRemote: false,
      );

      if (_disposed) return;

      if (!result.isFromCache) {
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
      }
    } catch (error) {
      Logger.debug('Category $_categoryId: silent refresh error — $error');
    }
  }

  void _registerForPolling() {
    PollingManager.instance.registerPoller(
      featureName: 'category_products',
      resourceId: _categoryId,
      onResume: _startPollingTimer,
      onPause: _stopPollingTimer,
    );
  }

  void _startPollingTimer() {
    if (_disposed) return;
    if (_pollingTimer != null) return;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (_disposed || state.isRefreshing) return;
      await _silentRefresh();
    });
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _showRefreshIndicator() {
    if (_disposed) return;
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(CacheConfig.refreshIndicatorDuration, () {
      if (_disposed) return;
      _safeSetState(state.copyWith(isRefreshing: false));
    });
  }

  String _mapError(Object error) {
    if (error is NetworkException) return error.message;
    if (error is FormatException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  void _handleDispose() {
    _disposed = true;

    PollingManager.instance.unregisterPoller(
      featureName: 'category_products',
      resourceId: _categoryId,
    );

    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer = null;
    _initialized = false;
  }
}

/// Controller for the Price Drop filter view.
///
/// Kept deliberately separate from [CategoryProductController]:
/// - no local cache (Price Drop is a transient filter, not a base list)
/// - no polling (the underlying list will also be polled when the filter is off)
/// - no conditional-request headers
///
/// Reuses [CategoryProductState] so the UI can render either provider
/// interchangeably.
final categoryDiscountProductControllerProvider = NotifierProviderFamily<
    CategoryDiscountProductController, CategoryProductState, String>(
  CategoryDiscountProductController.new,
);

class CategoryDiscountProductController
    extends FamilyNotifier<CategoryProductState, String> {
  bool _initialized = false;
  bool _disposed = false;
  late String _categoryId;

  @override
  CategoryProductState build(String categoryId) {
    _categoryId = categoryId;
    _disposed = false;

    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }

    ref.onDispose(() {
      _disposed = true;
      _initialized = false;
    });

    return CategoryProductState.initial();
  }

  Future<void> refresh() async {
    await _loadInitial(forceRefresh: true);
  }

  Future<void> _loadInitial({bool forceRefresh = false}) async {
    if (_disposed) return;

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
      final remote = ref.read(categoryProductRemoteDataSourceProvider);
      final response = await remote.fetchDiscountedProducts(_categoryId);
      if (_disposed) return;

      final List<CategoryProduct> products = response == null
          ? const <CategoryProduct>[]
          : response.products.map((dto) => dto.toDomain()).toList(
                growable: false,
              );

      _safeSetState(
        state.copyWith(
          status: products.isEmpty
              ? CategoryProductStatus.empty
              : CategoryProductStatus.data,
          products: products,
          isRefreshing: false,
          lastSyncedAt: DateTime.now(),
          totalCount: response?.count,
          next: response?.next,
          previous: response?.previous,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed) return;
      Logger.error(
        'Category $_categoryId discount fetch failed',
        error: error,
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

  void _safeSetState(CategoryProductState newState) {
    if (_disposed) return;
    state = newState;
  }

  String _mapError(Object error) {
    if (error is NetworkException) return error.message;
    if (error is FormatException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
