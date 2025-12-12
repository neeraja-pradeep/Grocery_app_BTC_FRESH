import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';

import '../../domain/repositories/product_detail_repository.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/product_base.dart';
import '../../infrastructure/data_sources/local/product_detail_local_data_source.dart';
import '../../infrastructure/data_sources/remote/product_detail_remote_data_source.dart';
import '../../infrastructure/repositories/product_detail_repository_impl.dart';
import '../states/product_detail_state.dart';
import '../config/product_detail_config.dart';
import '../../../../core/polling/polling_manager.dart';

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
      return ProductDetailLocalDataSourceImpl();
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
  // Use global polling interval from config - allows easy adjustment across entire feature
  static final Duration _pollingInterval = ProductDetailConfig.pollingInterval;

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
    // Register for polling - timer will start when 'product_detail' feature becomes active
    _registerForPolling();
  }

  /// Load initial data from repository (cache or remote)
  /// Passes forceRefresh: true to bypass cache TTL and fetch fresh data from server
  /// Also fetches product base data and merges with variant data
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
        // Fetch product base data to get description, rating, media
        final productBase = await _repository.getProductBase(
          productDetail.productId.toString(),
          forceRefresh: true,
        );

        // Merge product base data into variant data
        final mergedProduct = _mergeProductData(productDetail, productBase);

        state = state.copyWith(
          status: ProductDetailStatus.data,
          productDetail: mergedProduct,
          productBase: productBase,
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
  /// Fetches BOTH variant API (conditional) and product API (fresh) independently
  /// - Variant API: If-Modified-Since optimization (304 or 200)
  /// - Product API: Always fresh data (no If-Modified-Since)
  /// Merges data from both APIs before updating state
  Future<void> _refreshInternal({bool forceRemote = false}) async {
    try {
      // ALWAYS fetch both APIs independently
      // Variant API: Uses conditional requests (304 or 200)
      final variantResult = await _repository.getProductDetail(_variantId);

      // Get the product ID for product API call
      // Use existing state's product ID if variant returned 304
      final productId =
          variantResult?.productId ?? state.productDetail?.productId;
      if (productId == null) {
        throw Exception('Cannot determine product ID for product API call');
      }

      // Product API: Always fetch fresh (no If-Modified-Since logic)
      final productBaseResponse = await _repository.getProductBase(
        productId.toString(),
      );

      // Determine which data to use
      // If variant returned 304, use existing variant data
      final variantDataToUse = variantResult ?? state.productDetail;

      if (variantDataToUse == null) {
        throw Exception('No variant data available');
      }

      // Use new product base if API returned 200, otherwise keep existing
      // null = 304 or no change (use cached data)
      final productBase = productBaseResponse ?? state.productBase;

      // Check if anything changed
      final variantChanged = variantResult != null;
      final productChanged = productBaseResponse != null;

      if (!variantChanged && !productChanged) {
        // Both APIs returned no changes - keep state as is
        developer.log(
          'Polling variant $_variantId: 304 Not Modified (variant), product unchanged',
          name: 'ProductDetail',
        );
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        );
        _scheduleIndicatorReset();
        return;
      }

      // Merge product base data into variant data
      final mergedProduct = _mergeProductData(variantDataToUse, productBase);

      // Log what changed
      final changeLog = [
        if (variantChanged) 'variant 200 OK' else 'variant 304 Not Modified',
        if (productChanged) 'product 200 OK' else 'product (cached)',
      ].join(', ');

      developer.log(
        'Polling variant $_variantId: $changeLog (UI updated)',
        name: 'ProductDetail',
      );

      state = state.copyWith(
        status: ProductDetailStatus.data,
        productDetail: mergedProduct,
        productBase: productBase,
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

  /// Merge product base data into variant data
  /// Fills in description, rating, and media from product base if available
  ProductVariant _mergeProductData(
    ProductVariant variant,
    ProductBase? productBase,
  ) {
    if (productBase == null) {
      return variant;
    }

    return ProductVariant(
      id: variant.id,
      sku: variant.sku,
      name: variant.name,
      variantName: variant.variantName,
      productId: variant.productId,
      trackInventory: variant.trackInventory,
      price: variant.price,
      originalPrice: variant.originalPrice,
      discountedPrice: variant.discountedPrice,
      isSelected: variant.isSelected,
      isPreorder: variant.isPreorder,
      preorderEndDate: variant.preorderEndDate,
      preorderGlobalThreshold: variant.preorderGlobalThreshold,
      quantityLimitPerCustomer: variant.quantityLimitPerCustomer,
      createdAt: variant.createdAt,
      updatedAt: variant.updatedAt,
      weight: variant.weight,
      status: variant.status,
      tags: variant.tags,
      barCode: variant.barCode,
      // Use product base media if available, otherwise use variant media
      media: productBase.media ?? variant.media,
      currentQuantity: variant.currentQuantity,
      stockUnit: variant.stockUnit,
      prodDescription: variant.prodDescription,
      productRating: variant.productRating,
      warehouseName: variant.warehouseName,
      categoryId: variant.categoryId,
      // Use product base description if available
      description: productBase.description ?? variant.description,
      reviews: variant.reviews,
      nutritionFacts: variant.nutritionFacts,
      images: variant.images,
      imageUrl: variant.imageUrl,
      thumbnailUrl: variant.thumbnailUrl,
      // Use product base rating if available
      rating: productBase.rating ?? variant.rating,
      // Use product base reviewCount if available
      reviewCount: productBase.reviewCount ?? variant.reviewCount,
    );
  }

  /// Register for polling with PollingManager
  ///
  /// IMPORTANT: This does NOT start the polling timer immediately!
  /// The timer only starts when PollingManager calls onResume,
  /// which happens when the 'product_detail' feature is active.
  ///
  /// PAGE-FOCUSED POLLING:
  /// - Timer starts only when user is viewing the product detail screen
  /// - Timer stops when user navigates to Cart, Categories, etc.
  /// - This prevents unnecessary API calls for inactive pages
  ///
  /// Efficiency:
  /// - Per-product polling: Each product has its own timer
  /// - Disposed when screen closes: No background polling
  /// - Conditional requests: Tiny 304 responses save bandwidth
  void _registerForPolling() {
    // Register with PollingManager - timer will start when feature is active
    PollingManager.instance.registerPoller(
      featureName: 'product_detail',
      resourceId: _variantId,
      onResume: _startPollingTimer,
      onPause: _stopPollingTimer,
    );

    developer.log(
      'Registered polling for variant $_variantId (waiting for activation)',
      name: 'ProductDetail',
      level: 700,
    );
  }

  /// Start the polling timer (called by PollingManager when 'product_detail' feature becomes active)
  void _startPollingTimer() {
    if (_pollingTimer != null) return; // Already running

    developer.log(
      'Starting polling timer for variant $_variantId (interval: ${_pollingInterval.inSeconds}s)',
      name: 'ProductDetail',
      level: 700,
    );

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == ProductDetailStatus.loading) {
        return;
      }
      await refresh();
    });
  }

  /// Stop the polling timer (called by PollingManager when 'product_detail' feature becomes inactive)
  void _stopPollingTimer() {
    if (_pollingTimer != null) {
      developer.log(
        'Stopping polling timer for variant $_variantId',
        name: 'ProductDetail',
        level: 700,
      );
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Schedule reset of refresh indicators
  /// Duration controlled globally via ProductDetailConfig
  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(ProductDetailConfig.refreshIndicatorDuration, () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  /// Toggle wishlist status
  Future<bool> toggleWishlist() async {
    // Block guests from adding to wishlist
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      state = state.copyWith(
        errorMessage: 'Please login to add items to wishlist',
      );
      return false;
    }

    try {
      if (state.isInWishlist) {
        await _repository.removeFromWishlist(_variantId);
        state = state.copyWith(isInWishlist: false);
      } else {
        await _repository.addToWishlist(_variantId);
        state = state.copyWith(isInWishlist: true);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update wishlist: $e');
      return false;
    }
  }

  /// Update quantity
  void setQuantity(int quantity) {
    if (quantity >= 0) {
      state = state.copyWith(quantity: quantity);
    }
  }

  /// Add current product to cart
  /// Calls the CheckoutLineController to persist the cart item
  Future<void> addToCart() async {
    if (state.quantity <= 0) {
      developer.log('Cannot add to cart: quantity is 0', name: 'ProductDetail');
      return;
    }

    final variantId = int.tryParse(_variantId);
    if (variantId == null) {
      developer.log(
        'Cannot add to cart: invalid variant ID',
        name: 'ProductDetail',
      );
      return;
    }

    try {
      // Import and call the checkout line controller
      final checkoutController = ref.read(
        checkoutLineControllerProvider.notifier,
      );
      await checkoutController.addToCart(
        productVariantId: variantId,
        quantity: state.quantity,
      );

      developer.log(
        'Added to cart: variant $variantId, quantity ${state.quantity}',
        name: 'ProductDetail',
      );
    } catch (e) {
      developer.log('Failed to add to cart: $e', name: 'ProductDetail');
      rethrow;
    }
  }

  /// Dispose resources
  void _disposeController() {
    // Unregister from PollingManager
    PollingManager.instance.unregisterPoller(
      featureName: 'product_detail',
      resourceId: _variantId,
    );

    // Cancel timers
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _initialized = false;

    developer.log(
      'ProductDetailController disposed for variant $_variantId',
      name: 'ProductDetail',
      level: 700,
    );
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
