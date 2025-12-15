import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../models/address_dto.dart';

/// Response model for address list with cache headers
class AddressListRemoteResponse {
  AddressListRemoteResponse({
    required this.addressList,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final AddressListResponseDto addressList;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
}

/// Remote data source for fetching and managing addresses from API
abstract class AddressRemoteDataSource {
  /// Fetch address list with conditional headers (supports 304 Not Modified)
  /// Returns null if server responds with 304 (not modified)
  Future<AddressListRemoteResponse?> fetchAddressList({
    String? ifNoneMatch,
    String? ifModifiedSince,
  });

  /// Create a new address
  Future<AddressDto> createAddress({
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
  Future<AddressDto> updateAddress({
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
  Future<AddressDto> selectAddress(int id);
}

/// Implementation using API Client (DIO)
class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  AddressRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AddressListRemoteResponse?> fetchAddressList({
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      final headers = <String, String>{};

      // Add conditional headers if provided
      if (ifNoneMatch != null) {
        headers['If-None-Match'] = ifNoneMatch;
      }
      if (ifModifiedSince != null) {
        headers['If-Modified-Since'] = ifModifiedSince;
      }

      // Log the request with conditional headers
      if (headers.isNotEmpty) {
        developer.log(
          'SENDING CONDITIONAL REQUEST for addresses\nHeaders: ${headers.toString()}',
          name: 'AddressRemoteDataSource',
          level: 700,
        );
      } else {
        developer.log(
          'SENDING UNCONDITIONAL REQUEST for addresses (no cache)',
          name: 'AddressRemoteDataSource',
          level: 700,
        );
      }

      final response = await _apiClient.get(
        '/api/auth/v1/address/',
        headers: headers.isNotEmpty ? headers : null,
      );

      final statusCode = response.statusCode ?? 200;
      final responseHeaders = response.headers;

      // Handle 304 Not Modified
      if (statusCode == 304) {
        developer.log(
          'Addresses: HTTP 304 (bandwidth optimized)',
          name: 'RemoteDataSource',
        );
        return null; // Data hasn't changed
      }

      // Extract cache headers from response
      final eTag =
          responseHeaders.value('etag') ?? responseHeaders.value('ETag');
      final lastModified =
          responseHeaders.value('last-modified') ??
          responseHeaders.value('Last-Modified');

      developer.log(
        'Addresses: HTTP 200 (Last-Modified: $lastModified)',
        name: 'RemoteDataSource',
      );

      return AddressListRemoteResponse(
        addressList: AddressListResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        ),
        fetchedAt: DateTime.now(),
        eTag: eTag,
        lastModified: lastModified,
      );
    } on NetworkException catch (error) {
      // Handle 304 Not Modified wrapped in NetworkException
      if (error.statusCode == 304) {
        developer.log(
          'Addresses: HTTP 304 (via NetworkException)',
          name: 'RemoteDataSource',
        );
        return null;
      }
      developer.log(
        'Addresses: NetworkException - $error',
        name: 'RemoteDataSource',
      );
      rethrow;
    } on DioException catch (error) {
      developer.log(
        'Addresses: DioException - $error',
        name: 'RemoteDataSource',
      );
      throw NetworkException.fromDio(error);
    } on FormatException catch (error) {
      developer.log(
        'Addresses: FormatException - $error',
        name: 'RemoteDataSource',
      );
      throw NetworkException(message: error.message);
    } catch (e) {
      developer.log('Addresses: Error - $e', name: 'RemoteDataSource');
      rethrow;
    }
  }

  @override
  Future<AddressDto> createAddress({
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
      final data = {
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
        'address_type': addressType,
      };

      final response = await _apiClient.post(
        '/api/auth/v1/address/',
        data: data,
      );

      return AddressDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AddressDto> updateAddress({
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
      final data = <String, dynamic>{};

      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (streetAddress1 != null) data['street_address1'] = streetAddress1;
      if (streetAddress2 != null) data['street_address2'] = streetAddress2;
      if (city != null) data['city'] = city;
      if (state != null) data['state'] = state;
      if (postalCode != null) data['postal_code'] = postalCode;
      if (country != null) data['country'] = country;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (addressType != null) data['address_type'] = addressType;
      if (selected != null) data['selected'] = selected;

      final response = await _apiClient.patch(
        '/api/auth/v1/address/$id/',
        data: data,
      );

      return AddressDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(int id) async {
    try {
      await _apiClient.delete('/api/auth/v1/address/$id/');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AddressDto> selectAddress(int id) async {
    try {
      // Update the address to set selected = true
      return await updateAddress(id: id, selected: true);
    } catch (e) {
      rethrow;
    }
  }
}
