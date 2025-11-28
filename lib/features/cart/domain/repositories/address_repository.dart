import '../entities/address.dart';

/// Repository interface for address data operations
abstract class AddressRepository {
  /// Fetch address list with HTTP conditional request optimization
  /// Returns null if server responds with 304 Not Modified
  Future<AddressListResponse?> getAddressList({bool forceRefresh = false});

  /// Create a new address
  Future<Address> createAddress({
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
  });

  /// Update an existing address
  Future<Address> updateAddress({
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
  });

  /// Delete an address
  Future<void> deleteAddress(int id);

  /// Select an address (mark as selected)
  Future<Address> selectAddress(int id);
}
