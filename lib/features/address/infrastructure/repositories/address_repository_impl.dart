import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../data_sources/local/address_local_ds.dart';
import '../data_sources/remote/address_api.dart';

/// Result of fetching addresses with cache information
class AddressFetchResult {
  const AddressFetchResult({
    required this.addresses,
    required this.isStale,
    required this.fromCache,
  });

  final List<Address> addresses;
  final bool isStale;
  final bool fromCache;
}

class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl({
    required AddressApi remoteDs,
    required AddressLocalDs localDs,
  }) : _remoteDs = remoteDs,
       _localDs = localDs;

  final AddressApi _remoteDs;
  final AddressLocalDs _localDs;

  /// Fetches addresses with cache-first strategy:
  /// 1. Returns cached data immediately if available (even if stale)
  /// 2. Triggers background API refresh
  /// Returns AddressFetchResult with cache metadata
  Future<AddressFetchResult> fetchAddressesWithCache() async {
    // Step 1: Try to get cached data first
    final cachedResult = await _localDs.getCachedAddresses();

    if (cachedResult != null) {
      // Return cached data immediately
      return AddressFetchResult(
        addresses: cachedResult.addresses.map((dto) => dto.toDomain()).toList(),
        isStale: cachedResult.isStale,
        fromCache: true,
      );
    }

    // Step 2: No cache available, must fetch from API
    try {
      final addressDtos = await _remoteDs.fetchAddresses();

      // Cache asynchronously (non-blocking)
      _localDs.cacheAddressListAsync(addressDtos);

      return AddressFetchResult(
        addresses: addressDtos.map((dto) => dto.toDomain()).toList(),
        isStale: false,
        fromCache: false,
      );
    } catch (error) {
      // API failed and no cache - rethrow error
      rethrow;
    }
  }

  /// Refreshes addresses from API (background refresh)
  /// Returns fresh data or null if fails
  Future<List<Address>?> refreshAddressesFromApi() async {
    try {
      final addressDtos = await _remoteDs.fetchAddresses();

      // Cache asynchronously (non-blocking)
      _localDs.cacheAddressListAsync(addressDtos);

      return addressDtos.map((dto) => dto.toDomain()).toList();
    } catch (error) {
      // Silently fail - cache remains unchanged
      return null;
    }
  }

  @override
  Future<List<Address>> fetchAddresses() async {
    // Backward compatibility: behaves like fetchAddressesWithCache
    // but returns only the addresses list
    final result = await fetchAddressesWithCache();
    return result.addresses;
  }

  @override
  Future<Address> fetchAddressById(String id) async {
    final addressDto = await _remoteDs.fetchAddressById(id);
    return addressDto.toDomain();
  }

  @override
  Future<Address> createAddress({
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? latitude,
    String? longitude,
    String? addressType,
    bool? selected,
  }) async {
    final addressDto = await _remoteDs.createAddress(
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

    // Invalidate cache after creating new address
    // User will fetch fresh list on next load
    await _localDs.clearCache();

    return addressDto.toDomain();
  }

  @override
  Future<Address> updateAddress({
    required String id,
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? latitude,
    String? longitude,
    String? addressType,
    bool? selected,
  }) async {
    final addressDto = await _remoteDs.updateAddress(
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

    // Invalidate cache after updating address
    await _localDs.clearCache();

    return addressDto.toDomain();
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _remoteDs.deleteAddress(id);

    // Invalidate cache after deleting address
    await _localDs.clearCache();
  }

  @override
  Future<Address> selectAddress(String id) async {
    final addressDto = await _remoteDs.selectAddress(id);

    // Invalidate cache after selecting address
    await _localDs.clearCache();

    return addressDto.toDomain();
  }

  @override
  Future<void> logout() async {
    // Clear all cached address data on logout
    await _localDs.clearAll();
  }
}
