import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../../cart/application/providers/address_providers.dart';
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/user_address.dart';
import '../../domain/entities/address.dart';
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
    NotifierProvider.autoDispose<ProfileAddressController, AddressState>(
      ProfileAddressController.new,
    );

class ProfileAddressController extends AutoDisposeNotifier<AddressState> {
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
      final result = await _repository.fetchAddressesWithCache();

      // Apply local selection override if we have one
      // This works around the buggy backend GET endpoint that returns wrong selected address
      final localSelectedId = state.localSelectedAddressId;
      final correctedAddresses = localSelectedId != null
          ? result.addresses.map((addr) {
              return Address(
                id: addr.id,
                firstName: addr.firstName,
                lastName: addr.lastName,
                streetAddress1: addr.streetAddress1,
                streetAddress2: addr.streetAddress2,
                city: addr.city,
                state: addr.state,
                postalCode: addr.postalCode,
                country: addr.country,
                latitude: addr.latitude,
                longitude: addr.longitude,
                addressType: addr.addressType,
                selected: addr.id == localSelectedId,
                createdAt: addr.createdAt,
                updatedAt: addr.updatedAt,
              );
            }).toList()
          : result.addresses;

      // Update UI immediately with cached/fresh data
      state = state.copyWith(
        status: AddressStatus.data,
        addresses: correctedAddresses,
        isStale: result.isStale,
        clearError: true,
      );

      // NOTE: Background refresh disabled to prevent overwriting optimistic updates
      // with stale backend data (backend has inconsistent selection state bug)
      // User can manually pull-to-refresh if needed
      // if (result.fromCache) {
      //   _refreshInBackground();
      // }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(
        status: AddressStatus.error,
        errorMessage: message,
      );
    }
  }

  // Background refresh removed - was overwriting optimistic updates with buggy backend data

  /// Manual refresh for pull-to-refresh
  Future<void> refreshAddresses() async {
    try {
      final freshAddresses = await _repository.refreshAddressesFromApi();

      if (freshAddresses != null) {
        // Apply local selection override if we have one
        // This works around the buggy backend GET endpoint that returns wrong selected address
        final localSelectedId = state.localSelectedAddressId;
        final correctedAddresses = localSelectedId != null
            ? freshAddresses.map((addr) {
                return Address(
                  id: addr.id,
                  firstName: addr.firstName,
                  lastName: addr.lastName,
                  streetAddress1: addr.streetAddress1,
                  streetAddress2: addr.streetAddress2,
                  city: addr.city,
                  state: addr.state,
                  postalCode: addr.postalCode,
                  country: addr.country,
                  latitude: addr.latitude,
                  longitude: addr.longitude,
                  addressType: addr.addressType,
                  selected: addr.id == localSelectedId,
                  createdAt: addr.createdAt,
                  updatedAt: addr.updatedAt,
                );
              }).toList()
            : freshAddresses;

        state = state.copyWith(
          status: AddressStatus.data,
          addresses: correctedAddresses,
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
      // Keep the cart/home-header bottom-sheet provider in sync so the new
      // address appears everywhere it's listed.
      await _syncCartAddressList();

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
      await _syncCartAddressList();

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

    final wasSelected = state.localSelectedAddressId == id;

    try {
      await _repository.deleteAddress(id);

      // Refresh the list after deleting
      await fetchAddresses();
      await _syncCartAddressList();

      // If the deleted address was the selected one, or no addresses remain,
      // clear the home screen's selected address so the UI doesn't show stale text.
      if (wasSelected || state.addresses.isEmpty) {
        ref.read(homeProvider.notifier).updateAddressInState(null);
        state = state.copyWith(
          isDeleting: false,
          clearError: true,
          clearLocalSelectedAddressId: true,
        );
      } else {
        state = state.copyWith(isDeleting: false, clearError: true);
      }
    } catch (error) {
      final message = _mapError(error);

      state = state.copyWith(isDeleting: false, errorMessage: message);

      rethrow;
    }
  }

  /// Select an address as the default delivery address.
  /// Updates local state and syncs homeProvider and cart addressControllerProvider.
  Future<void> selectAddress(String id) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final selectedAddress = await _repository.selectAddress(id);

      // Update local state to reflect the selection
      final updatedAddresses = state.addresses.map((addr) {
        return Address(
          id: addr.id,
          firstName: addr.firstName,
          lastName: addr.lastName,
          streetAddress1: addr.streetAddress1,
          streetAddress2: addr.streetAddress2,
          city: addr.city,
          state: addr.state,
          postalCode: addr.postalCode,
          country: addr.country,
          latitude: addr.latitude,
          longitude: addr.longitude,
          addressType: addr.addressType,
          selected: addr.id == id,
          createdAt: addr.createdAt,
          updatedAt: addr.updatedAt,
        );
      }).toList();

      state = state.copyWith(
        isUpdating: false,
        clearError: true,
        addresses: updatedAddresses,
        // Track locally selected address to override buggy API during refresh
        localSelectedAddressId: id,
      );

      // Sync home provider with the selected address from the API PATCH response
      final numericId = int.tryParse(selectedAddress.id);
      final userAddress = UserAddress(
        id: numericId ?? 0,
        firstName: selectedAddress.firstName,
        lastName: selectedAddress.lastName,
        streetAddress1: selectedAddress.streetAddress1,
        streetAddress2: selectedAddress.streetAddress2,
        city: selectedAddress.city ?? '',
        state: selectedAddress.state ?? '',
        postalCode: selectedAddress.postalCode ?? '',
        country: selectedAddress.country ?? '',
        latitude: selectedAddress.latitude,
        longitude: selectedAddress.longitude,
        addressType: selectedAddress.addressType ?? 'home',
        selected: true,
        createdAt: selectedAddress.createdAt != null
            ? DateTime.tryParse(selectedAddress.createdAt!) ?? DateTime.now()
            : DateTime.now(),
      );
      ref.read(homeProvider.notifier).updateAddressInState(userAddress);

      // Sync cart address provider so checkout sees the updated selection
      if (numericId != null) {
        ref.read(addressControllerProvider.notifier).selectAddress(numericId);
      }
    } catch (error) {
      final message = _mapError(error);
      state = state.copyWith(isUpdating: false, errorMessage: message);
      rethrow;
    }
  }

  /// Refresh the cart's address provider so the home header bottom sheet
  /// and checkout flows immediately reflect a profile-side mutation.
  /// Best-effort — failures here must not break the profile mutation.
  Future<void> _syncCartAddressList() async {
    try {
      await ref.read(addressControllerProvider.notifier).refresh();
    } catch (_) {
      // Best-effort — the profile-side data is already correct.
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(profileAddressLocalDsProvider).clearAll();
      state = AddressState.initial();
    } catch (error) {
      // Even if logout fails, reset the state
      state = AddressState.initial();
      rethrow;
    }
  }

  /// Set local selected address ID without making API call
  /// Used when selection is made from another provider (e.g., cart bottom sheet)
  void setLocalSelectedAddressId(String id) {
    // Update local state to reflect the selection
    final updatedAddresses = state.addresses.map((addr) {
      return Address(
        id: addr.id,
        firstName: addr.firstName,
        lastName: addr.lastName,
        streetAddress1: addr.streetAddress1,
        streetAddress2: addr.streetAddress2,
        city: addr.city,
        state: addr.state,
        postalCode: addr.postalCode,
        country: addr.country,
        latitude: addr.latitude,
        longitude: addr.longitude,
        addressType: addr.addressType,
        selected: addr.id == id,
        createdAt: addr.createdAt,
        updatedAt: addr.updatedAt,
      );
    }).toList();

    state = state.copyWith(
      addresses: updatedAddresses,
      localSelectedAddressId: id,
    );
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
