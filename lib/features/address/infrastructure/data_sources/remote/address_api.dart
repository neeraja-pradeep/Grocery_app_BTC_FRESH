import '../../../../../core/network/api_client.dart';
import '../../models/address_dto.dart';

class AddressApi {
  const AddressApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Fetches all addresses for the current user
  Future<List<AddressDto>> fetchAddresses() async {
    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/v1/address/',
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty address list response.');
    }

    // API returns paginated response with 'results' array
    final results = data['results'] as List?;
    if (results == null) {
      throw const FormatException('Missing results in address list response.');
    }

    return results
        .map((json) => AddressDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single address by ID
  Future<AddressDto> fetchAddressById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/v1/address/$id/',
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty address response.');
    }

    return AddressDto.fromJson(data);
  }

  /// Creates a new address
  Future<AddressDto> createAddress({
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
    final response = await _client.post<Map<String, dynamic>>(
      'api/auth/v1/address/',
      data: <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'street_address1': streetAddress1,
        if (streetAddress2 != null) 'street_address2': streetAddress2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postal_code': postalCode,
        if (country != null) 'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (addressType != null) 'address_type': addressType,
        if (selected != null) 'selected': selected,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty create address response.');
    }

    return AddressDto.fromJson(data);
  }

  /// Updates an existing address
  Future<AddressDto> updateAddress({
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
    final response = await _client.patch<Map<String, dynamic>>(
      'api/auth/v1/address/$id/',
      data: <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'street_address1': streetAddress1,
        if (streetAddress2 != null) 'street_address2': streetAddress2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postal_code': postalCode,
        if (country != null) 'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (addressType != null) 'address_type': addressType,
        if (selected != null) 'selected': selected,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty update address response.');
    }

    return AddressDto.fromJson(data);
  }

  /// Deletes an address
  Future<void> deleteAddress(String id) async {
    await _client.delete<void>('api/auth/v1/address/$id/');
  }

  /// Selects an address as the default delivery address
  Future<AddressDto> selectAddress(String id) async {
    final response = await _client.patch<Map<String, dynamic>>(
      'api/auth/v1/address/$id/',
      data: <String, dynamic>{'selected': true},
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty select address response.');
    }

    return AddressDto.fromJson(data);
  }

  /// Fetches the selected address using ?selected=true filter
  /// DEBUG: Used to verify backend behavior
  Future<AddressDto?> fetchSelectedAddress() async {
    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/v1/address/',
      queryParameters: {'selected': 'true'},
    );

    final data = response.data;
    if (data == null) {
      return null;
    }

    final results = data['results'] as List?;
    if (results == null || results.isEmpty) {
      return null;
    }

    return AddressDto.fromJson(results.first as Map<String, dynamic>);
  }
}
