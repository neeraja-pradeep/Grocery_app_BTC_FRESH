import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/repositories/address_repository.dart';
import '../../infrastructure/data_sources/local/address_local_ds.dart';
import '../../infrastructure/data_sources/remote/address_api.dart';
import '../../infrastructure/repositories/address_repository_impl.dart';
import '../states/address_state.dart';

/// Profile address local data source provider
/// Named with "profile" prefix to distinguish from cart feature's address providers
final profileAddressLocalDsProvider = Provider<AddressLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.address);
  return AddressLocalDs(box: box);
});

/// Profile address API provider
final profileAddressApiProvider = Provider<AddressApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressApi(client: apiClient);
});

/// Profile address repository provider
final profileAddressRepositoryProvider = Provider<AddressRepository>((ref) {
  final remoteDs = ref.watch(profileAddressApiProvider);
  final localDs = ref.watch(profileAddressLocalDsProvider);

  return AddressRepositoryImpl(remoteDs: remoteDs, localDs: localDs);
});

/// Profile address controller provider
/// Manages addresses from Profile > My Addresses screen
/// For cart/checkout addresses, use cart's addressControllerProvider instead
final profileAddressControllerProvider =
    NotifierProvider<ProfileAddressController, AddressState>(
      ProfileAddressController.new,
    );

class ProfileAddressController extends Notifier<AddressState> {
  AddressRepository get _repository =>
      ref.read(profileAddressRepositoryProvider);

  @override
  AddressState build() {
    return AddressState.initial();
  }

  /// Fetches addresses with cache-first strategy:
  /// 1. Shows cached data immediately (even if stale)
  /// 2. Always triggers background API refresh when showing cached data
  Future<void> fetchAddresses() async {
    // Only show loading if no data exists
    if (state.addresses.isEmpty) {
      state = state.copyWith(status: AddressStatus.loading, clearError: true);
    }

    try {
      final repoImpl = _repository as AddressRepositoryImpl;
      final result = await repoImpl.fetchAddressesWithCache();

      // Update UI immediately with cached/fresh data
      state = state.copyWith(
        status: AddressStatus.data,
        addresses: result.addresses,
        isStale: result.isStale,
        clearError: true,
      );

      // Always trigger background refresh when showing cached data
      // This ensures backend changes are fetched even if cache is fresh
      if (result.fromCache) {
        _refreshInBackground();
      }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        status: AddressStatus.error,
        errorMessage: message,
      );
    }
  }

  /// Background refresh without blocking UI
  void _refreshInBackground() {
    final repoImpl = _repository as AddressRepositoryImpl;
    repoImpl
        .refreshAddressesFromApi()
        .then((freshAddresses) {
          if (freshAddresses != null) {
            // Update state with fresh data
            state = state.copyWith(
              addresses: freshAddresses,
              isStale: false,
              clearError: true,
            );
          }
        })
        .catchError((_) {
          // Silently fail - user already has cached data
        });
  }

  /// Manual refresh for pull-to-refresh
  Future<void> refreshAddresses() async {
    try {
      final repoImpl = _repository as AddressRepositoryImpl;
      final freshAddresses = await repoImpl.refreshAddressesFromApi();

      if (freshAddresses != null) {
        state = state.copyWith(
          status: AddressStatus.data,
          addresses: freshAddresses,
          isStale: false,
          clearError: true,
        );
      } else {
        // API failed, but keep existing data
        throw Exception('Failed to refresh addresses');
      }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(errorMessage: message);

      rethrow;
    }
  }

  Future<void> createAddress({
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? country,
    String? latitude,
    String? longitude,
    String? addressType,
    bool? selected,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);

    try {
      await _repository.createAddress(
        firstName: firstName,
        lastName: lastName,
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        city: city,
        state: stateProvince,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        addressType: addressType,
        selected: selected,
      );

      // Refresh the list after creating
      await fetchAddresses();

      state = state.copyWith(isCreating: false, clearError: true);
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isCreating: false, errorMessage: message);

      rethrow;
    }
  }

  Future<void> updateAddress({
    required String id,
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? country,
    String? latitude,
    String? longitude,
    String? addressType,
    bool? selected,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _repository.updateAddress(
        id: id,
        firstName: firstName,
        lastName: lastName,
        streetAddress1: streetAddress1,
        streetAddress2: streetAddress2,
        city: city,
        state: stateProvince,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        addressType: addressType,
        selected: selected,
      );

      // Refresh the list after updating
      await fetchAddresses();

      state = state.copyWith(
        isUpdating: false,
        isStale: false,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isUpdating: false, errorMessage: message);

      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      await _repository.deleteAddress(id);

      // Refresh the list after deleting
      await fetchAddresses();

      state = state.copyWith(isDeleting: false, clearError: true);
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isDeleting: false, errorMessage: message);

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      state = AddressState.initial();
    } catch (error) {
      // Even if logout fails, reset the state
      state = AddressState.initial();
      rethrow;
    }
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
}
