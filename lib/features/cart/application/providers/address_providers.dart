import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';

import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../../infrastructure/data_sources/local/address_local_data_source.dart';
import '../../infrastructure/data_sources/remote/address_remote_data_source.dart';
import '../../infrastructure/repositories/address_repository_impl.dart';
import '../states/address_state.dart';

/// ============================================================================
/// ADDRESS LIST POLLING SYSTEM - UNCONDITIONAL 30-SECOND UPDATES
/// ============================================================================
///
/// This implementation uses HTTP conditional requests with unconditional polling
/// to keep address list fresh and responsive.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD:
///    - Fetch address list from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive
///    - Display addresses to user
///
/// 2. PERIODIC POLLING (every 30 seconds, UNCONDITIONAL):
///    - Timer fires every 30 seconds without exception
///    - Send conditional GET with If-Modified-Since header
///    - Server returns 304: Keep using cached data, UI not refreshed
///    - Server returns 200: New data available, update cache + Last-Modified + UI
///
/// 3. CACHE STORAGE (Hive):
///    - address_list: AddressListResponse
///    - last_synced_at: When we last synced with server
///    - last_modified: Server's Last-Modified header (for If-Modified-Since)
///    - etag: Alternate validation mechanism
///
/// SINGLETON POLLING:
/// ------------------
/// Uses regular Notifier (not AutoDispose) to maintain polling across navigation.
/// Polling continues even when screen is not visible.
/// Call ref.invalidate(addressControllerProvider) to stop polling.
///
/// REFRESH BEHAVIOR:
/// ----------------
/// Every 30 seconds: Unconditional network request (304 or 200)
/// 304 Not Modified: Tiny response (< 1KB), keeps cache, no UI update
/// 200 OK: New data, updates cache and triggers UI rebuild
/// Safeguards: Skips refresh if already refreshing or still loading initial data
/// ============================================================================

/// Riverpod Providers for Address Feature

/// Local data source provider
final addressLocalDataSourceProvider = Provider<AddressLocalDataSource>((ref) {
  return AddressLocalDataSourceImpl();
});

/// Remote data source provider
final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressRemoteDataSourceImpl(apiClient);
});

/// Repository provider
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final localDataSource = ref.watch(addressLocalDataSourceProvider);
  final remoteDataSource = ref.watch(addressRemoteDataSourceProvider);

  return AddressRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});

/// Address list controller - manages address list state with 30-second polling
class AddressController extends Notifier<AddressState> {
  // Use global polling interval from CacheConfig - same 30 seconds as product_details
  static const Duration _pollingInterval = CacheConfig.pollingInterval;

  late AddressRepository _repository;
  bool _initialized = false;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  AddressState build() {
    final repository = ref.watch(addressRepositoryProvider);
    _repository = repository;

    // Cleanup handler (non-AutoDispose, so manual cleanup on invalidate)
    ref.onDispose(_disposeController);

    // Schedule async initialization after notifier is ready
    Future.microtask(_initialize);

    return const AddressState();
  }

  /// Initialize and load data
  Future<void> _initialize() async {
    if (_initialized) {
      return; // Already initialized
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
        status: AddressStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
      );

      final addressList = await _repository.getAddressList(forceRefresh: true);

      // addressList is null only when server returns 304 (data unchanged)
      // This shouldn't happen on initial load (forceRefresh=true)
      if (addressList == null) {
        state = state.copyWith(
          status: AddressStatus.error,
          errorMessage: 'No address data available',
          isRefreshing: false,
        );
      } else if (addressList.results.isEmpty) {
        state = state.copyWith(
          status: AddressStatus.empty,
          addressList: addressList,
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      } else {
        state = state.copyWith(
          status: AddressStatus.data,
          addressList: addressList,
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      }

      _scheduleIndicatorReset();
    } catch (e) {
      state = state.copyWith(
        status: AddressStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh address list data
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
    );

    await _refreshInternal();
  }

  /// Internal refresh logic with conditional request support
  /// Uses If-Modified-Since optimization (304 or 200)
  Future<void> _refreshInternal() async {
    try {
      // Fetch with conditional request (304 or 200)
      final addressListResult = await _repository.getAddressList();

      // 304 Not Modified - no changes on server
      if (addressListResult == null) {
        developer.log(
          'Polling addresses: 304 Not Modified (no UI update)',
          name: 'AddressController',
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
        'Polling addresses: 200 OK (UI updated)',
        name: 'AddressController',
      );

      final newStatus = addressListResult.results.isEmpty
          ? AddressStatus.empty
          : AddressStatus.data;

      state = state.copyWith(
        status: newStatus,
        addressList: addressListResult,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      developer.log(
        'Polling failed for addresses: $e',
        name: 'AddressController',
      );

      state = state.copyWith(
        status: AddressStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    }
  }

  /// Create a new address
  Future<void> createAddress({
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    required String addressType,
  }) async {
    try {
      await _repository.createAddress(
        firstName: firstName,
        lastName: lastName,
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        addressType: addressType,
      );

      // Refresh list after creating
      await refresh();
    } catch (e) {
      developer.log('Failed to create address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Update an existing address
  Future<void> updateAddress({
    required int id,
    String? firstName,
    String? lastName,
    String? streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? addressType,
    bool? selected,
  }) async {
    try {
      await _repository.updateAddress(
        id: id,
        firstName: firstName,
        lastName: lastName,
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        addressType: addressType,
        selected: selected,
      );

      // Refresh list after updating
      await refresh();
    } catch (e) {
      developer.log('Failed to update address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(int id) async {
    try {
      await _repository.deleteAddress(id);

      // Force refresh to bypass 304 conditional request
      // After delete, we need fresh data from server
      await _forceRefresh();
    } catch (e) {
      developer.log('Failed to delete address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Force refresh bypassing conditional requests (304)
  /// Used after mutations (create/update/delete) to ensure fresh data
  Future<void> _forceRefresh() async {
    state = state.copyWith(
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
    );

    try {
      final addressList = await _repository.getAddressList(forceRefresh: true);

      if (addressList == null) {
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        );
        return;
      }

      final newStatus = addressList.results.isEmpty
          ? AddressStatus.empty
          : AddressStatus.data;

      state = state.copyWith(
        status: newStatus,
        addressList: addressList,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      developer.log('Force refresh failed: $e', name: 'AddressController');
      state = state.copyWith(
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );
      _scheduleIndicatorReset();
    }
  }

  /// Select an address (mark as selected)
  Future<void> selectAddress(int id) async {
    try {
      await _repository.selectAddress(id);

      // Refresh list after selecting
      await refresh();
    } catch (e) {
      developer.log('Failed to select address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Set local selected address (UI-only, no API call)
  /// This allows users to select an address for checkout without authentication
  void setLocalSelectedAddress(Address address) {
    state = state.copyWith(localSelectedAddress: address);
  }

  /// Start automatic polling every 30 seconds for address list.
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
  /// - Singleton polling: One timer for entire app
  /// - Conditional requests: Tiny 304 responses save bandwidth
  /// - Unconditional timing: Guarantees responsive UI updates
  void _startPolling() {
    // Register with PollingManager for screen-aware polling
    // DO NOT start timer here - wait for onResume callback
    PollingManager.instance.registerPoller(
      featureName: 'cart',
      resourceId: 'addresses',
      onResume: _resumePolling,
      onPause: _pausePolling,
    );
  }

  /// Actually start the polling timer (called by PollingManager when cart feature is active)
  void _startPollingTimer() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == AddressStatus.loading) {
        return;
      }
      await refresh();
    });
  }

  /// Resume polling when user navigates back to cart/address screen
  void _resumePolling() {
    if (_pollingTimer == null) {
      developer.log(
        'Resuming polling for cart addresses',
        name: 'AddressController',
        level: 700,
      );
      _startPollingTimer();
    }
  }

  /// Pause polling when user navigates away from cart/address screen
  void _pausePolling() {
    if (_pollingTimer != null) {
      developer.log(
        'Pausing polling for cart addresses',
        name: 'AddressController',
        level: 700,
      );
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Schedule reset of refresh indicators
  /// Duration controlled globally via CacheConfig
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
    PollingManager.instance.unregisterPoller(
      featureName: 'cart',
      resourceId: 'addresses',
    );
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _initialized = false;
  }
}

/// Address list provider with Notifier for singleton state
/// Uses regular Notifier (not AutoDispose) to maintain polling across navigation
final addressControllerProvider =
    NotifierProvider<AddressController, AddressState>(AddressController.new);
