import 'dart:async';

import 'package:flutter/foundation.dart';
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
/// PRODUCT DETAIL LAST-MODIFIED UPDATE SYSTEM
/// ============================================================================
///
/// This implementation uses HTTP conditional requests to efficiently check
/// for updates without downloading unchanged data.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD:
///    - Fetch product detail from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive
///    - Display product to user
///
/// 2. PERIODIC POLLING (every 30 seconds, but only if TTL expired):
///    - Check if cache is older than 10 minutes (TTL)
///    - If cache is fresh: Skip polling (save bandwidth)
///    - If cache is stale: Send conditional GET with If-Modified-Since
///    - Server returns 304: Keep using cached data, reset TTL timer
///    - Server returns 200: New data available, update cache + Last-Modified
///
/// 3. CACHE STORAGE (Hive):
///    - product_detail: ProductVariantDto
///    - last_synced_at: When we last checked
///    - last_modified: Server's Last-Modified header (for If-Modified-Since)
///    - etag: Alternate validation mechanism
///
/// PER-PRODUCT POLLING:
/// --------------------
/// Each product has its own polling timer (FamilyNotifier pattern).
/// When product screen closes, the polling timer is disposed.
/// This prevents unnecessary polling for products not being viewed.
///
/// BANDWIDTH OPTIMIZATION:
/// -----------------------
/// 304 Not Modified responses are tiny (< 1KB), saving bandwidth when
/// data hasn't changed. Only fresh data (200 OK) triggers UI updates.
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
    extends FamilyNotifier<ProductDetailState, String> {
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const Duration _cacheTTL = Duration(minutes: 10);

  late ProductDetailRepository _repository;
  late String _productId;
  bool _initialized = false;
  DateTime? _lastRefreshAttempt;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  ProductDetailState build(String productId) {
    _productId = productId;
    final repository = ref.watch(productDetailRepositoryProvider);
    _repository = repository;

    ref.onDispose(_disposeController);

    // Auto-initialize on creation
    _initialize();

    return const ProductDetailState();
  }

  /// Initialize with product ID and load data
  Future<void> _initialize() async {
    if (kDebugMode) {
      debugPrint(
        '[ProductDetailController] _initialize() called with productId: $_productId',
      );
      debugPrint(
        '[ProductDetailController] Already initialized: $_initialized',
      );
    }

    if (_initialized) {
      if (kDebugMode) {
        debugPrint(
          '[ProductDetailController] Already initialized for this product, skipping',
        );
      }
      return; // Already initialized for this product
    }

    _initialized = true;

    if (kDebugMode) {
      debugPrint(
        '[ProductDetailController] Starting initialization for product: $_productId',
      );
    }

    await _loadInitial();
    _startPolling();
  }

  /// Load initial data from repository (cache or remote)
  Future<void> _loadInitial() async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ProductDetailController] Loading initial data for product: $_productId',
        );
      }

      state = state.copyWith(
        status: ProductDetailStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
      );

      final productDetail = await _repository.getProductDetail(_productId);

      if (kDebugMode) {
        debugPrint(
          '[ProductDetailController] Successfully loaded product: ${productDetail.name}',
        );
        debugPrint(
          '[ProductDetailController] Product media count: ${productDetail.media?.length ?? 0}',
        );
        debugPrint(
          '[ProductDetailController] Product image URL: ${productDetail.imageUrl}',
        );
      }

      state = state.copyWith(
        status: ProductDetailStatus.data,
        productDetail: productDetail,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
      );

      _scheduleIndicatorReset();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductDetailController] Error loading product: $e');
      }

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

  /// Internal refresh logic
  Future<void> _refreshInternal({bool forceRemote = false}) async {
    try {
      final result = await _repository.getProductDetail(_productId);

      state = state.copyWith(
        status: ProductDetailStatus.data,
        productDetail: result,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      state = state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh only if cache is stale (TTL expired).
  ///
  /// Smart caching strategy:
  /// - Cache is fresh if < 10 minutes old → Skip polling (save bandwidth)
  /// - Cache is stale if >= 10 minutes old → Check server with If-Modified-Since
  /// - Prevents rapid consecutive requests (min 30 seconds between attempts)
  ///
  /// Server responses:
  /// - 304 Not Modified: Data unchanged, reset TTL timer
  /// - 200 OK: New data available, update cache + Last-Modified
  Future<void> _refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    // Don't refresh if already refreshed in last 30 seconds
    final recentlyRequested =
        _lastRefreshAttempt != null &&
        now.difference(_lastRefreshAttempt!) < _pollingInterval;
    if (recentlyRequested) return;

    // Only refresh if cache TTL expired (10 minutes)
    if (lastSyncedAt == null || now.difference(lastSyncedAt) >= _cacheTTL) {
      _lastRefreshAttempt = now;
      await refresh();
    }
  }

  /// Start automatic polling every 30 seconds for this product.
  ///
  /// How it works:
  /// 1. Timer fires every 30 seconds
  /// 2. Calls _refreshIfStale() to check if data needs updating
  /// 3. _refreshIfStale() reads If-Modified-Since from Hive
  /// 4. If cache is fresh (< 10 min): Skip (lightweight check, no network)
  /// 5. If cache is stale (>= 10 min): Send conditional GET request
  /// 6. Server returns 304 or 200, UI updates accordingly
  ///
  /// Efficiency:
  /// - Per-product polling: Each product has its own timer
  /// - Disposed when screen closes: No background polling
  /// - Skips if cache is fresh: Most polls are just local checks
  /// - Prevents overlapping requests: Skip if already refreshing
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == ProductDetailStatus.loading) {
        return;
      }
      await _refreshIfStale();
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
        await _repository.removeFromWishlist(_productId);
        state = state.copyWith(isInWishlist: false);
      } else {
        await _repository.addToWishlist(_productId);
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
    _lastRefreshAttempt = null;
  }
}

/// Product detail provider with NotifierProviderFamily for per-product state
final productDetailControllerProvider =
    NotifierProvider.family<
      ProductDetailController,
      ProductDetailState,
      String
    >(ProductDetailController.new);
