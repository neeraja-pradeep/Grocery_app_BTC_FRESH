import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';
import '../../domain/entities/checkout_line.dart';
import '../../infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../states/checkout_line_state.dart';

/// Data source provider
final checkoutLineDataSourceProvider = Provider<CheckoutLineDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckoutLineDataSource(apiClient);
});

/// Checkout lines controller - manages cart state with 30-second polling
class CheckoutLineController extends Notifier<CheckoutLineState> {
  static const Duration _pollingInterval = CacheConfig.pollingInterval;
  static const Duration _debounceDelay = Duration(milliseconds: 150);

  late CheckoutLineDataSource _dataSource;
  bool _initialized = false;
  bool _disposed = false;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  // Quantity update debouncing - prevents rapid tap race conditions
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, int> _pendingDeltas = {};
  final Set<int> _processingLines = {};

  @override
  CheckoutLineState build() {
    final dataSource = ref.watch(checkoutLineDataSourceProvider);
    _dataSource = dataSource;
    //_disposed = false;
    //_initialized = false; // Reset on rebuild to ensure initialization runs
    //_pollingTimer?.cancel();
    //_pollingTimer = null;

    ref.onDispose(_disposeController);

    // Listen to auth state changes - reload cart when switching from guest to authenticated
    ref.listen<AuthState>(authProvider, (previous, next) {
      // When user becomes authenticated (from any previous state), reload cart
      if (next is Authenticated && previous is! Authenticated) {
        developer.log(
          'Auth state changed to Authenticated - reloading cart',
          name: 'CheckoutLineController',
        );
        Future.microtask(() => _forceRefresh());
      }
      // When user logs out (becomes guest from authenticated), clear cart
      else if (next is GuestMode && previous is Authenticated) {
        developer.log(
          'Auth state changed from Authenticated to Guest - clearing cart',
          name: 'CheckoutLineController',
        );
        state = const CheckoutLineState();
      }
    });

    // Only initialize cart if user is authenticated
    final currentAuthState = ref.read(authProvider);
    if (currentAuthState is Authenticated) {
      Future.microtask(_initialize);
    }

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
    // Register for polling - timer will start when 'cart' feature becomes active
    _registerForPolling();
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

  /// Update quantity with debouncing to handle rapid taps
  /// [delta] is a delta value (+1 for increment, -1 for decrement)
  /// API expects delta values: positive for increment, negative for decrement
  /// If the resulting quantity is 0 or less, the item will be deleted
  ///
  /// DEBOUNCING LOGIC:
  /// - Rapid taps accumulate deltas (e.g., tap-tap-tap = delta of 3)
  /// - UI updates immediately (optimistic)
  /// - API call is debounced - only fires after 300ms of no taps
  /// - Prevents race conditions from concurrent API calls
  Future<void> updateQuantity({required int lineId, required int delta}) async {
    if (_disposed) return;

    // If this line is currently being processed by API, ignore new taps
    if (_processingLines.contains(lineId)) {
      developer.log(
        'Ignoring tap - line $lineId is processing',
        name: 'CheckoutLineController',
      );
      return;
    }

    // Find the current item
    final currentItem = state.checkoutLines?.results.firstWhere(
      (item) => item.id == lineId,
      orElse: () => throw Exception('Item not found in cart'),
    );

    if (currentItem == null) {
      throw Exception('Item not found in cart');
    }

    // Accumulate delta for this line
    _pendingDeltas[lineId] = (_pendingDeltas[lineId] ?? 0) + delta;
    final cumulativeDelta = _pendingDeltas[lineId]!;

    // Calculate new quantity for UI (from ORIGINAL server quantity + cumulative delta)
    final originalQuantity = currentItem.quantity - (cumulativeDelta - delta);
    final newQuantity = originalQuantity + cumulativeDelta;

    developer.log(
      'Debounce: line=$lineId, delta=$delta, cumulative=$cumulativeDelta, '
      'original=$originalQuantity, new=$newQuantity',
      name: 'CheckoutLineController',
    );

    // If quantity becomes 0 or less, delete immediately
    if (newQuantity <= 0) {
      _debounceTimers[lineId]?.cancel();
      _debounceTimers.remove(lineId);
      _pendingDeltas.remove(lineId);
      await deleteCheckoutLine(lineId);
      return;
    }

    // Optimistic UI update - show new quantity immediately
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

    // Cancel existing debounce timer for this line
    _debounceTimers[lineId]?.cancel();

    // Start new debounce timer - API call fires after delay
    _debounceTimers[lineId] = Timer(_debounceDelay, () async {
      await _executeQuantityUpdate(
        lineId: lineId,
        productVariantId: currentItem.productVariantId,
      );
    });
  }

  /// Execute the actual API call after debounce delay
  Future<void> _executeQuantityUpdate({
    required int lineId,
    required int productVariantId,
  }) async {
    if (_disposed) return;

    final cumulativeDelta = _pendingDeltas[lineId];
    if (cumulativeDelta == null || cumulativeDelta == 0) {
      _pendingDeltas.remove(lineId);
      return;
    }

    // Mark line as processing to block further taps + update UI
    _processingLines.add(lineId);
    _pendingDeltas.remove(lineId);
    _debounceTimers.remove(lineId);

    // Update state to show processing indicator in UI
    _safeSetState(
      state.copyWith(processingLineIds: Set.from(_processingLines)),
    );

    // Store state for rollback (with processing state)
    final originalCheckoutLines = state.checkoutLines;

    try {
      developer.log(
        'API call: line=$lineId, delta=$cumulativeDelta',
        name: 'CheckoutLineController',
      );

      // Make API call with cumulative delta
      await _dataSource.updateQuantity(
        lineId: lineId,
        productVariantId: productVariantId,
        quantity: cumulativeDelta,
      );

      // Force refresh to get server state
      await _forceRefresh();
    } on InsufficientStockException catch (e) {
      // Rollback on insufficient stock error
      _safeSetState(state.copyWith(checkoutLines: originalCheckoutLines));
      developer.log(
        'Insufficient stock: ${e.message}',
        name: 'CheckoutLineController',
      );
      // Note: Can't rethrow here as we're in a timer callback
      // The UI will show the rollback state
    } catch (e) {
      // Rollback on error
      _safeSetState(state.copyWith(checkoutLines: originalCheckoutLines));
      developer.log(
        'Failed to update quantity: $e',
        name: 'CheckoutLineController',
      );
    } finally {
      // Remove from processing and update UI
      _processingLines.remove(lineId);
      _safeSetState(
        state.copyWith(processingLineIds: Set.from(_processingLines)),
      );
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

  /// Register for polling with PollingManager
  ///
  /// IMPORTANT: This does NOT start the polling timer immediately!
  /// The timer only starts when PollingManager calls onResume,
  /// which happens when the 'cart' feature is active.
  ///
  /// PAGE-FOCUSED POLLING:
  /// - Timer starts only when user is viewing the Cart screen
  /// - Timer stops when user navigates to Categories, Profile, etc.
  /// - This prevents unnecessary API calls for inactive pages
  void _registerForPolling() {
    // Register with PollingManager - timer will start when feature is active
    PollingManager.instance.registerPoller(
      featureName: 'cart',
      resourceId: 'lines',
      onResume: _startPollingTimer,
      onPause: _stopPollingTimer,
    );

    developer.log(
      'Registered polling for cart lines (waiting for activation)',
      name: 'CheckoutLineController',
      level: 700,
    );
  }

  /// Start the polling timer (called by PollingManager when 'cart' feature becomes active)
  void _startPollingTimer() {
    if (_disposed) return;
    if (_pollingTimer != null) return; // Already running

    developer.log(
      'Starting polling timer for cart lines (interval: ${_pollingInterval.inSeconds}s)',
      name: 'CheckoutLineController',
      level: 700,
    );

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (_disposed) return;
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CheckoutLineStatus.loading) {
        return;
      }
      await refresh();
    });
  }

  /// Stop the polling timer (called by PollingManager when 'cart' feature becomes inactive)
  void _stopPollingTimer() {
    if (_pollingTimer != null) {
      developer.log(
        'Stopping polling timer for cart lines',
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

    // Clean up debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingDeltas.clear();
    _processingLines.clear();
  }
}

/// Checkout lines provider with Notifier for singleton state
final checkoutLineControllerProvider =
    NotifierProvider<CheckoutLineController, CheckoutLineState>(
      CheckoutLineController.new,
    );
