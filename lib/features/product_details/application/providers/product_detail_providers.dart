import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/storage/hive/boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/repositories/product_detail_repository.dart';
import '../../infrastructure/data_sources/local/product_detail_local_data_source.dart';
import '../../infrastructure/data_sources/remote/product_detail_remote_data_source.dart';
import '../../infrastructure/repositories/product_detail_repository_impl.dart';
import '../states/product_detail_state.dart';

/// ============================================================================
/// PRODUCT DETAIL POLLING SYSTEM - UNCONDITIONAL 30-SECOND UPDATES
/// ============================================================================
///
/// This implementation uses HTTP conditional requests with unconditional polling
/// to keep product details fresh and responsive.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD:
///    - Fetch product detail from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive
///    - Display product to user
///
/// 2. PERIODIC POLLING (every 30 seconds, UNCONDITIONAL):
///    - Timer fires every 30 seconds without exception
///    - Send conditional GET with If-Modified-Since header
///    - Server returns 304: Keep using cached data, UI not refreshed
///    - Server returns 200: New data available, update cache + Last-Modified + UI
///
/// 3. CACHE STORAGE (Hive):
///    - product_detail: ProductVariantDto
///    - last_synced_at: When we last synced with server
///    - last_modified: Server's Last-Modified header (for If-Modified-Since)
///    - etag: Alternate validation mechanism
///
/// PER-PRODUCT POLLING:
/// --------------------
/// Each product has its own polling timer (FamilyNotifier pattern).
/// When product screen closes, the polling timer is disposed.
/// This prevents unnecessary polling for products not being viewed.
///
/// REFRESH BEHAVIOR:
/// ----------------
/// Every 30 seconds: Unconditional network request (304 or 200)
/// 304 Not Modified: Tiny response (< 1KB), keeps cache, no UI update
/// 200 OK: New data, updates cache and triggers UI rebuild
/// Safeguards: Skips refresh if already refreshing or still loading initial data
/// ============================================================================

/// Riverpod Providers for Product Details Feature

/// Local data source provider
final productDetailLocalDataSourceProvider =
    Provider<ProductDetailLocalDataSource>((ref) {
      final box = Hive.box<dynamic>(AppHiveBoxes.cache);
      return ProductDetailLocalDataSourceImpl(box);
    });

/// Remote data source provider
final productDetailRemoteDataSourceProvider =
    Provider<ProductDetailRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ProductDetailRemoteDataSourceImpl(apiClient);
    });

/// Repository provider
final productDetailRepositoryProvider = Provider<ProductDetailRepository>((
  ref,
) {
  final localDataSource = ref.watch(productDetailLocalDataSourceProvider);
  final remoteDataSource = ref.watch(productDetailRemoteDataSourceProvider);

  return ProductDetailRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});

/// Product detail controller - manages product detail state with polling
class ProductDetailController
    extends AutoDisposeFamilyNotifier<ProductDetailState, String> {
  static const Duration _pollingInterval = Duration(seconds: 30);

  late ProductDetailRepository _repository;
  late String _variantId;
  bool _initialized = false;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  ProductDetailState build(String variantId) {
    _variantId = variantId;
    final repository = ref.watch(productDetailRepositoryProvider);
    _repository = repository;

    // Auto-dispose cleanup handler
    ref.onDispose(_disposeController);

    // Schedule async initialization after notifier is ready
    Future.microtask(_initialize);

    return const ProductDetailState();
  }

  /// Initialize with variant ID and load data
  Future<void> _initialize() async {
    if (_initialized) {
      return; // Already initialized for this variant
    }

    _initialized = true;

    await _loadInitial();
    _startPolling();
  }

  /// Load initial data from repository (cache or remote)
  /// Passes forceRefresh: true to bypass cache TTL and fetch fresh data from server
  Future<void> _loadInitial() async {
    try {
      state = state.copyWith(
        status: ProductDetailStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
      );

      final productDetail = await _repository.getProductDetail(
        _variantId,
        forceRefresh: true,
      );

      // productDetail is null only when server returns 304 (data unchanged)
      // This shouldn't happen on initial load (forceRefresh=true)
      if (productDetail == null) {
        state = state.copyWith(
          status: ProductDetailStatus.error,
          errorMessage: 'No product data available',
          isRefreshing: false,
        );
      } else {
        state = state.copyWith(
          status: ProductDetailStatus.data,
          productDetail: productDetail,
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      }

      _scheduleIndicatorReset();
    } catch (e) {
      state = state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh product data
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
    );

    await _refreshInternal(forceRemote: false);
  }

  /// Internal refresh logic with conditional request support
  /// Returns null when server responds with 304 (no data change)
  Future<void> _refreshInternal({bool forceRemote = false}) async {
    try {
      final result = await _repository.getProductDetail(_variantId);

      // null = 304 Not Modified (data unchanged, don't update UI)
      if (result == null) {
        developer.log(
          'Polling variant $_variantId: 304 Not Modified (no UI update)',
          name: 'ProductDetail',
        );
        // Don't update state - UI remains unchanged
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        );
        _scheduleIndicatorReset();
        return;
      }

      // 200 OK (data changed, update UI)
      developer.log(
        'Polling variant $_variantId: 200 OK (UI updated)',
        name: 'ProductDetail',
      );

      state = state.copyWith(
        status: ProductDetailStatus.data,
        productDetail: result,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      developer.log(
        'Polling failed for variant $_variantId: $e',
        name: 'ProductDetail',
      );

      state = state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Start automatic polling every 30 seconds for this product.
  ///
  /// How it works:
  /// 1. Timer fires every 30 seconds unconditionally
  /// 2. Calls refresh() to check for updates
  /// 3. Sends conditional GET with If-Modified-Since header
  /// 4. Server returns 304 Not Modified: Keep cached data, no UI update
  /// 5. Server returns 200 OK: New data, update cache + state, UI rebuilds
  ///
  /// Safeguards:
  /// - Skips if already refreshing (prevents overlapping requests)
  /// - Skips if loading initial data (prevents request overload)
  ///
  /// Efficiency:
  /// - Per-product polling: Each product has its own timer
  /// - Disposed when screen closes: No background polling
  /// - Conditional requests: Tiny 304 responses save bandwidth
  /// - Unconditional timing: Guarantees responsive UI updates
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == ProductDetailStatus.loading) {
        return;
      }
      await refresh();
    });
  }

  /// Schedule reset of refresh indicators after 1.5 seconds
  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  /// Toggle wishlist status
  Future<void> toggleWishlist() async {
    try {
      if (state.isInWishlist) {
        await _repository.removeFromWishlist(_variantId);
        state = state.copyWith(isInWishlist: false);
      } else {
        await _repository.addToWishlist(_variantId);
        state = state.copyWith(isInWishlist: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update wishlist: $e');
    }
  }

  /// Update quantity
  void setQuantity(int quantity) {
    if (quantity >= 0) {
      state = state.copyWith(quantity: quantity);
    }
  }

  /// Dispose resources
  void _disposeController() {
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _initialized = false;
  }
}

/// Product detail provider with AutoDisposeNotifierProviderFamily for per-product state
/// Uses AutoDispose to clean up timers and resources when screen is closed
final productDetailControllerProvider =
    AutoDisposeNotifierProviderFamily<
      ProductDetailController,
      ProductDetailState,
      String
    >(ProductDetailController.new);
