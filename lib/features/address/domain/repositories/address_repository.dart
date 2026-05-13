import '../entities/address.dart';

/// Result of fetching addresses with cache metadata
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

abstract class AddressRepository {
  /// Fetches all addresses for the current user
  Future<List<Address>> fetchAddresses();

  /// Fetches addresses using cache-first strategy.
  /// Returns cached data immediately (even if stale) and includes cache metadata.
  Future<AddressFetchResult> fetchAddressesWithCache();

  /// Refreshes addresses directly from the API, bypassing cache.
  /// Returns fresh data or null if the request fails.
  Future<List<Address>?> refreshAddressesFromApi();

  /// Fetches a single address by ID
  Future<Address> fetchAddressById(String id);

  /// Creates a new address
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
  });

  /// Updates an existing address
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
  });

  /// Deletes an address
  Future<void> deleteAddress(String id);

  /// Selects an address as the default delivery address
  /// Returns the selected address from the API response
  Future<Address> selectAddress(String id);
}
