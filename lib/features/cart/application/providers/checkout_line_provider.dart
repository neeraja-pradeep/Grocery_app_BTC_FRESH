import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/polling/polling_manager.dart';
import 'package:grocery_app/core/storage/cache_config.dart';
import '../../domain/entities/checkout_line.dart';
import '../../infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../states/checkout_line_state.dart';

/// Data source provider
final checkoutLineDataSourceProvider = Provider<CheckoutLineDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckoutLineDataSource(apiClient);
});

/// Checkout lines controller - manages cart state with 30-second polling
class CheckoutLineController extends Notifier<CheckoutLineState> {
  static final Duration _pollingInterval = CacheConfig.pollingInterval;

  late CheckoutLineDataSource _dataSource;
  bool _initialized = false;
  bool _disposed = false;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CheckoutLineState build() {
    final dataSource = ref.watch(checkoutLineDataSourceProvider);
    _dataSource = dataSource;
    //_disposed = false;
    //_initialized = false; // Reset on rebuild to ensure initialization runs
    //_pollingTimer?.cancel();
    //_pollingTimer = null;

    ref.onDispose(_disposeController);

    Future.microtask(_initialize);

    return const CheckoutLineState();
  }

  /// Safely update state only if not disposed
  void _safeSetState(CheckoutLineState newState) {
    if (_disposed) return;
    state = newState;
  }

  /// Initialize and load data
  Future<void> _initialize() async {
    if (_initialized) return;

    _initialized = true;

    await _loadInitial();
    _startPolling();
  }

  /// Load initial data
  Future<void> _loadInitial() async {
    if (_disposed) return;

    try {
      _safeSetState(
        state.copyWith(
          status: CheckoutLineStatus.loading,
          isRefreshing: true,
          refreshStartedAt: DateTime.now(),
        ),
      );

      final response = await _dataSource.fetchCheckoutLines();
      if (_disposed) return;

      if (response == null) {
        _safeSetState(
          state.copyWith(
            status: CheckoutLineStatus.error,
            errorMessage: 'No checkout data available',
            isRefreshing: false,
          ),
        );
      } else if (response.checkoutLines.results.isEmpty) {
        // Save cache metadata even if empty
        await _dataSource.saveCacheMetadata(
          lastModified: response.lastModified,
          etag: response.eTag,
        );

        _safeSetState(
          state.copyWith(
            status: CheckoutLineStatus.empty,
            checkoutLines: response.checkoutLines.toEntity(),
            lastSyncedAt: DateTime.now(),
            isRefreshing: false,
          ),
        );
      } else {
        // Save cache metadata
        await _dataSource.saveCacheMetadata(
          lastModified: response.lastModified,
          etag: response.eTag,
        );

        _safeSetState(
          state.copyWith(
            status: CheckoutLineStatus.data,
            checkoutLines: response.checkoutLines.toEntity(),
            lastSyncedAt: DateTime.now(),
            isRefreshing: false,
          ),
        );
      }

      _scheduleIndicatorReset();
    } catch (e) {
      if (_disposed) return;

      _safeSetState(
        state.copyWith(
          status: CheckoutLineStatus.error,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh checkout lines data (uses conditional headers for bandwidth optimization)
  Future<void> refresh() async {
    if (_disposed || state.isRefreshing) return;

    _safeSetState(
      state.copyWith(isRefreshing: true, refreshStartedAt: DateTime.now()),
    );

    await _refreshInternal(useConditionalHeaders: true);
  }

  /// Force refresh without conditional headers (used after mutations)
  Future<void> _forceRefresh() async {
    if (_disposed || state.isRefreshing) return;

    // Clear cache metadata to ensure fresh fetch
    await _dataSource.clearCacheMetadata();

    _safeSetState(
      state.copyWith(isRefreshing: true, refreshStartedAt: DateTime.now()),
    );

    await _refreshInternal(useConditionalHeaders: false);
  }

  /// Internal refresh logic with optional conditional request support
  Future<void> _refreshInternal({bool useConditionalHeaders = true}) async {
    if (_disposed) return;

    try {
      String? ifNoneMatch;
      String? ifModifiedSince;

      // Only use conditional headers if requested
      if (useConditionalHeaders) {
        final metadata = await _dataSource.getCacheMetadata();
        if (_disposed) return;
        ifNoneMatch = metadata['etag'];
        ifModifiedSince = metadata['lastModified'];
      }

      // Fetch with or without conditional request
      final response = await _dataSource.fetchCheckoutLines(
        ifNoneMatch: ifNoneMatch,
        ifModifiedSince: ifModifiedSince,
      );
      if (_disposed) return;

      // 304 Not Modified - no changes on server
      if (response == null) {
        developer.log(
          'Polling checkout lines: 304 Not Modified (no UI update)',
          name: 'CheckoutLineController',
        );
        _safeSetState(
          state.copyWith(isRefreshing: false, refreshEndedAt: DateTime.now()),
        );
        _scheduleIndicatorReset();
        return;
      }

      // 200 OK - new data from server
      developer.log(
        'Polling checkout lines: 200 OK (UI updated)',
        name: 'CheckoutLineController',
      );

      // Save cache metadata
      await _dataSource.saveCacheMetadata(
        lastModified: response.lastModified,
        etag: response.eTag,
      );
      if (_disposed) return;

      final newStatus = response.checkoutLines.results.isEmpty
          ? CheckoutLineStatus.empty
          : CheckoutLineStatus.data;

      _safeSetState(
        state.copyWith(
          status: newStatus,
          checkoutLines: response.checkoutLines.toEntity(),
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        ),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      if (_disposed) return;

      developer.log(
        'Polling failed for checkout lines: $e',
        name: 'CheckoutLineController',
      );

      _safeSetState(
        state.copyWith(
          status: CheckoutLineStatus.error,
          errorMessage: e.toString(),
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        ),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Update quantity with optimistic UI update
  /// [delta] is a delta value (+1 for increment, -1 for decrement)
  /// API expects delta values: positive for increment, negative for decrement
  /// If the resulting quantity is 0 or less, the item will be deleted
  Future<void> updateQuantity({required int lineId, required int delta}) async {
    if (_disposed) return;

    // Store original state for rollback
    final originalState = state;

    try {
      // Find the current item to calculate new quantity for UI
      final currentItem = state.checkoutLines?.results.firstWhere(
        (item) => item.id == lineId,
        orElse: () => throw Exception('Item not found in cart'),
      );

      if (currentItem == null) {
        throw Exception('Item not found in cart');
      }

      // Calculate new quantity for UI update
      final newQuantity = currentItem.quantity + delta;

      // If quantity becomes 0 or less, delete the item
      if (newQuantity <= 0) {
        await deleteCheckoutLine(lineId);
        return;
      }

      // Optimistic update - update UI immediately
      if (state.checkoutLines != null && !_disposed) {
        final updatedItems = state.checkoutLines!.results.map((item) {
          if (item.id == lineId) {
            return item.copyWith(quantity: newQuantity);
          }
          return item;
        }).toList();

        final updatedResponse = CheckoutLinesResponse(
          count: state.checkoutLines!.count,
          next: state.checkoutLines!.next,
          previous: state.checkoutLines!.previous,
          results: updatedItems,
        );

        _safeSetState(state.copyWith(checkoutLines: updatedResponse));
      }

      // Make API call with DELTA value (positive for increment, negative for decrement)
      await _dataSource.updateQuantity(
        lineId: lineId,
        productVariantId: currentItem.productVariantId,
        quantity: delta,
      );

      // Force refresh to get server state (no conditional headers)
      await _forceRefresh();
    } on InsufficientStockException catch (e) {
      // Rollback on insufficient stock error
      _safeSetState(originalState);

      developer.log(
        'Insufficient stock: ${e.message}',
        name: 'CheckoutLineController',
      );
      rethrow;
    } catch (e) {
      // Rollback on error
      _safeSetState(originalState);

      developer.log(
        'Failed to update quantity: $e',
        name: 'CheckoutLineController',
      );
      rethrow;
    }
  }

  /// Delete a checkout line
  Future<void> deleteCheckoutLine(int lineId) async {
    try {
      await _dataSource.deleteCheckoutLine(lineId);

      // Force refresh list after deleting (no conditional headers)
      await _forceRefresh();
    } catch (e) {
      developer.log(
        'Failed to delete checkout line: $e',
        name: 'CheckoutLineController',
      );
      rethrow;
    }
  }

  /// Add item to cart
  /// If the product variant already exists in cart, updates the quantity instead
  Future<void> addToCart({
    required int productVariantId,
    required int quantity,
  }) async {
    try {
      // Check if item already exists in cart
      CheckoutLine? existingItem;
      if (state.checkoutLines != null) {
        for (final item in state.checkoutLines!.results) {
          if (item.productVariantId == productVariantId) {
            existingItem = item;
            break;
          }
        }
      }

      if (existingItem != null) {
        // Item exists - update quantity by adding delta (API expects delta value)
        developer.log(
          'Item already in cart, updating quantity. Line ID: ${existingItem.id}, adding: $quantity',
          name: 'CheckoutLineController',
        );
        await _dataSource.updateQuantity(
          lineId: existingItem.id,
          productVariantId: productVariantId,
          quantity: quantity, // Delta value to add
        );
      } else {
        // New item - create new checkout line
        developer.log(
          'Adding new item to cart. Variant ID: $productVariantId',
          name: 'CheckoutLineController',
        );
        await _dataSource.addToCart(
          productVariantId: productVariantId,
          quantity: quantity,
        );
      }

      // Force refresh list after adding/updating (no conditional headers)
      await _forceRefresh();
    } catch (e) {
      developer.log(
        'Failed to add to cart: $e',
        name: 'CheckoutLineController',
      );
      rethrow;
    }
  }

  /// Start automatic polling every 30 seconds
  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CheckoutLineStatus.loading) {
        return;
      }
      await refresh();
    });

    // Register with PollingManager for screen-aware polling
    PollingManager.instance.registerPoller(
      featureName: 'cart',
      resourceId: 'lines',
      onResume: _resumePolling,
      onPause: _pausePolling,
    );
  }

  /// Resume polling when user navigates back to cart screen
  void _resumePolling() {
    if (_pollingTimer == null) {
      developer.log(
        'Resuming polling for cart lines',
        name: 'CheckoutLineController',
        level: 700,
      );
      _startPolling();
    }
  }

  /// Pause polling when user navigates away from cart screen
  void _pausePolling() {
    if (_pollingTimer != null) {
      developer.log(
        'Pausing polling for cart lines',
        name: 'CheckoutLineController',
        level: 700,
      );
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Schedule reset of refresh indicators
  void _scheduleIndicatorReset() {
    if (_disposed) return;

    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(CacheConfig.refreshIndicatorDuration, () {
      if (_disposed) return;
      _safeSetState(
        state.copyWith(resetRefreshStartedAt: true, resetRefreshEndedAt: true),
      );
    });
  }

  /// Dispose resources
  void _disposeController() {
    _disposed = true;
    PollingManager.instance.unregisterPoller(
      featureName: 'cart',
      resourceId: 'lines',
    );
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer = null;
    _initialized = false;
  }
}

/// Checkout lines provider with Notifier for singleton state
final checkoutLineControllerProvider =
    NotifierProvider<CheckoutLineController, CheckoutLineState>(
      CheckoutLineController.new,
    );
