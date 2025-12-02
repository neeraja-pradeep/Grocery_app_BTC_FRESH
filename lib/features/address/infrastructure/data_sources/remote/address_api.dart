import '../../../../../core/network/api_client.dart';
import '../../models/address_dto.dart';

class AddressApi {
  const AddressApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Fetches all addresses for the current user
  Future<List<AddressDto>> fetchAddresses() async {
    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/address/',
      headers: {'dev': '2'},
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
      'api/auth/address/$id/',
      headers: {'dev': '2'},
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
      'api/auth/address/',
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
      headers: {'dev': '2'},
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
      'api/auth/address/$id/',
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
      headers: {'dev': '2'},
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty update address response.');
    }

    return AddressDto.fromJson(data);
  }

  /// Deletes an address
  Future<void> deleteAddress(String id) async {
    await _client.delete<void>('api/auth/address/$id/', headers: {'dev': '2'});
  }
}
