import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';

import '../../../address/application/providers/address_provider.dart'
    as profile_addr;
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/user_address.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../../infrastructure/providers/address_infra_providers.dart';
import '../states/address_state.dart';

export '../../infrastructure/providers/address_infra_providers.dart'
    show addressRepositoryProvider;

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
        if (kDebugMode) {
          developer.log(
            'Polling addresses: 304 Not Modified (no UI update)',
            name: 'AddressController',
          );
        }
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        );
        _scheduleIndicatorReset();
        return;
      }

      // 200 OK - new data from server
      if (kDebugMode) {
        developer.log(
          'Polling addresses: 200 OK (UI updated)',
          name: 'AddressController',
        );
      }

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
      if (kDebugMode) {
        developer.log(
          'Polling failed for addresses: $e',
          name: 'AddressController',
        );
      }

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
      final created = await _repository.createAddress(
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

      // Auto-select the just-created address so the checkout flow uses it
      // immediately without the user having to tap it from the list.
      // Best-effort: if the backend rejects this (e.g. already selected),
      // fall back to a local-only selection so the UI still highlights it.
      try {
        await _repository.selectAddress(created.id);
      } catch (e) {
        if (kDebugMode) {
          developer.log(
            'Auto-select after create failed (non-fatal): $e',
            name: 'AddressController',
          );
        }
        setLocalSelectedAddress(created);
      }

      // Force refresh (bypass If-Modified-Since) — server's Last-Modified
      // header is too coarse to reflect a mutation we just made, so a
      // conditional GET would 304 and we'd keep stale state.
      await _forceRefresh();
      _syncHomeSelectedAddress();
      // Keep the profile address provider in sync so the profile address
      // list reflects the newly created entry.
      await _syncProfileAddressList();
    } catch (e) {
      if (kDebugMode) developer.log('Failed to create address: $e', name: 'AddressController');
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

      // Force refresh (bypass If-Modified-Since) — same reason as in
      // createAddress: a conditional GET right after a mutation would 304
      // and leave the UI showing pre-edit data.
      await _forceRefresh();
      _syncHomeSelectedAddress();
      await _syncProfileAddressList();
    } catch (e) {
      if (kDebugMode) developer.log('Failed to update address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(int id) async {
    try {
      await _repository.deleteAddress(id);

      // Drop any local override pointing at the row we just removed so the
      // subsequent home sync resolves to whatever is actually selected now.
      if (state.localSelectedAddress?.id == id) {
        state = state.copyWith(resetLocalSelectedAddress: true);
      }

      // Force refresh to bypass 304 conditional request
      // After delete, we need fresh data from server
      await _forceRefresh();
      _syncHomeSelectedAddress();
      await _syncProfileAddressList();
    } catch (e) {
      if (kDebugMode) developer.log('Failed to delete address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Public force-refresh entry point so external callers (e.g. the profile
  /// address provider after a mutation) can bypass the 304-conditional GET.
  Future<void> forceRefresh() => _forceRefresh();

  /// Push the cart-side selected address into [homeProvider] so the home
  /// header always mirrors the most recent selection / deletion. Called after
  /// every mutation that can change which address is selected.
  void _syncHomeSelectedAddress() {
    final selected = state.selectedAddress;
    final homeNotifier = ref.read(homeProvider.notifier);
    if (selected == null) {
      homeNotifier.updateAddressInState(null);
      return;
    }
    homeNotifier.updateAddressInState(
      UserAddress(
        id: selected.id,
        firstName: selected.firstName,
        lastName: selected.lastName,
        streetAddress1: selected.streetAddress1,
        streetAddress2: selected.streetAddress2,
        city: selected.city ?? '',
        state: selected.state ?? '',
        postalCode: selected.postalCode ?? '',
        country: selected.country ?? '',
        latitude: selected.latitude?.toString(),
        longitude: selected.longitude?.toString(),
        addressType: selected.addressType,
        selected: true,
        createdAt: selected.createdAt,
      ),
    );
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

      // If a previously locally-selected address no longer exists in the list
      // (e.g. it was deleted from the profile screen), drop the stale local
      // override so `selectedAddress` doesn't keep pointing at a phantom row.
      final localSelected = state.localSelectedAddress;
      final localGone = localSelected != null &&
          !addressList.results.any((a) => a.id == localSelected.id);

      state = state.copyWith(
        status: newStatus,
        addressList: addressList,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
        resetLocalSelectedAddress: localGone,
      );

      _scheduleIndicatorReset();
    } catch (e) {
      if (kDebugMode) developer.log('Force refresh failed: $e', name: 'AddressController');
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

      // Force-refresh: a conditional GET right after the PATCH can 304 and
      // leave the UI showing the previously-selected address.
      await _forceRefresh();
      _syncHomeSelectedAddress();
    } catch (e) {
      if (kDebugMode) developer.log('Failed to select address: $e', name: 'AddressController');
      rethrow;
    }
  }

  /// Set local selected address (UI-only, no API call)
  /// This allows users to select an address for checkout without authentication
  void setLocalSelectedAddress(Address address) {
    state = state.copyWith(localSelectedAddress: address);
  }

  /// Refresh the profile address provider so the profile address list
  /// reflects mutations performed via the cart/checkout flow.
  /// Best-effort — failures here must not break the cart mutation.
  ///
  /// Uses `refreshAddresses()` rather than `fetchAddresses()` because the
  /// profile repository's `fetchAddressesWithCache` is cache-first and
  /// returns stale cached data when present — only profile-side mutations
  /// invalidate that cache. `refreshAddresses()` always hits the API and
  /// rewrites the cache, so cross-feature mutations propagate correctly.
  Future<void> _syncProfileAddressList() async {
    try {
      await ref
          .read(profile_addr.profileAddressControllerProvider.notifier)
          .refreshAddresses();
    } catch (_) {
      // Best-effort — the cart-side data is already correct.
    }
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
      if (kDebugMode) {
        developer.log(
          'Resuming polling for cart addresses',
          name: 'AddressController',
          level: 700,
        );
      }
      _startPollingTimer();
    }
  }

  /// Pause polling when user navigates away from cart/address screen
  void _pausePolling() {
    if (_pollingTimer != null) {
      if (kDebugMode) {
        developer.log(
          'Pausing polling for cart addresses',
          name: 'AddressController',
          level: 700,
        );
      }
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
