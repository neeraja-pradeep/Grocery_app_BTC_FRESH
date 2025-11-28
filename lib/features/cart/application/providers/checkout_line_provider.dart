import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/api_client.dart';
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
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CheckoutLineState build() {
    final dataSource = ref.watch(checkoutLineDataSourceProvider);
    _dataSource = dataSource;

    ref.onDispose(_disposeController);

    Future.microtask(_initialize);

    return const CheckoutLineState();
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
    try {
      state = state.copyWith(
        status: CheckoutLineStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
      );

      final response = await _dataSource.fetchCheckoutLines();

      if (response == null) {
        state = state.copyWith(
          status: CheckoutLineStatus.error,
          errorMessage: 'No checkout data available',
          isRefreshing: false,
        );
      } else if (response.checkoutLines.results.isEmpty) {
        // Save cache metadata even if empty
        await _dataSource.saveCacheMetadata(
          lastModified: response.lastModified,
          etag: response.eTag,
        );

        state = state.copyWith(
          status: CheckoutLineStatus.empty,
          checkoutLines: response.checkoutLines.toEntity(),
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      } else {
        // Save cache metadata
        await _dataSource.saveCacheMetadata(
          lastModified: response.lastModified,
          etag: response.eTag,
        );

        state = state.copyWith(
          status: CheckoutLineStatus.data,
          checkoutLines: response.checkoutLines.toEntity(),
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      }

      _scheduleIndicatorReset();
    } catch (e) {
      state = state.copyWith(
        status: CheckoutLineStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh checkout lines data
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
    );

    await _refreshInternal();
  }

  /// Internal refresh logic with conditional request support
  Future<void> _refreshInternal() async {
    try {
      // Get cache metadata
      final metadata = await _dataSource.getCacheMetadata();

      // Fetch with conditional request
      final response = await _dataSource.fetchCheckoutLines(
        ifNoneMatch: metadata['etag'],
        ifModifiedSince: metadata['lastModified'],
      );

      // 304 Not Modified - no changes on server
      if (response == null) {
        developer.log(
          'Polling checkout lines: 304 Not Modified (no UI update)',
          name: 'CheckoutLineController',
        );
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
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

      final newStatus = response.checkoutLines.results.isEmpty
          ? CheckoutLineStatus.empty
          : CheckoutLineStatus.data;

      state = state.copyWith(
        status: newStatus,
        checkoutLines: response.checkoutLines.toEntity(),
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      developer.log(
        'Polling failed for checkout lines: $e',
        name: 'CheckoutLineController',
      );

      state = state.copyWith(
        status: CheckoutLineStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Update quantity with optimistic UI update
  /// [quantity] is a delta value (+1 for increment, -1 for decrement)
  Future<void> updateQuantity({
    required int lineId,
    required int quantity,
  }) async {
    // Store original state for rollback
    final originalState = state;

    try {
      // Optimistic update - update UI immediately by applying delta
      if (state.checkoutLines != null) {
        final updatedItems = state.checkoutLines!.results.map((item) {
          if (item.id == lineId) {
            // Apply delta to current quantity
            var newQuantity = item.quantity + quantity;
            // Prevent going below 1
            if (newQuantity < 1) {
              newQuantity = 1;
            }
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

        state = state.copyWith(checkoutLines: updatedResponse);
      }

      // Make API call with delta value
      await _dataSource.updateQuantity(lineId: lineId, quantity: quantity);

      // Refresh to get server state
      await refresh();
    } on InsufficientStockException catch (e) {
      // Rollback on insufficient stock error
      state = originalState;

      developer.log(
        'Insufficient stock: ${e.message}',
        name: 'CheckoutLineController',
      );
      rethrow;
    } catch (e) {
      // Rollback on error
      state = originalState;

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

      // Refresh list after deleting
      await refresh();
    } catch (e) {
      developer.log(
        'Failed to delete checkout line: $e',
        name: 'CheckoutLineController',
      );
      rethrow;
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required int checkoutId,
    required int productVariantId,
    required int quantity,
  }) async {
    try {
      await _dataSource.addToCart(
        checkoutId: checkoutId,
        productVariantId: productVariantId,
        quantity: quantity,
      );

      // Refresh list after adding
      await refresh();
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
  }

  /// Schedule reset of refresh indicators
  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(CacheConfig.refreshIndicatorDuration, () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  /// Dispose resources
  void _disposeController() {
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _initialized = false;
  }
}

/// Checkout lines provider with Notifier for singleton state
final checkoutLineControllerProvider =
    NotifierProvider<CheckoutLineController, CheckoutLineState>(
      CheckoutLineController.new,
    );
