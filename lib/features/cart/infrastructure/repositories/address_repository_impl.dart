import 'dart:developer' as developer;
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../data_sources/local/address_local_data_source.dart';
import '../data_sources/local/address_cache_dto.dart';
import '../data_sources/remote/address_remote_data_source.dart';

/// Implementation of AddressRepository
/// Combines local cache and remote API with HTTP conditional headers support
class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({
    required AddressLocalDataSource localDataSource,
    required AddressRemoteDataSource remoteDataSource,
    this.cacheTTL = const Duration(hours: 1),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final AddressLocalDataSource _localDataSource;
  final AddressRemoteDataSource _remoteDataSource;
  final Duration cacheTTL;

  /// Fetches address list with If-Modified-Since optimization.
  ///
  /// DESIGN: Metadata-only Hive caching (following product_details pattern)
  ///
  /// Returns:
  /// - AddressListResponse: Server returned 200 OK (new data, UI will refresh)
  /// - null: Server returned 304 Not Modified (no change, UI stays same)
  ///
  /// FLOW:
  /// -----
  /// 1. Get cached metadata (lastModified, eTag) from Hive
  /// 2. Always fetch from API with If-Modified-Since header
  /// 3. Server response:
  ///    - 304: No change on server, return null (UI doesn't refresh)
  ///    - 200: New data from server, save metadata, return data (UI refreshes)
  ///
  /// WHY METADATA-ONLY CACHING:
  /// --------------------------
  /// - Address data is in-memory in Riverpod state (not persistent)
  /// - On app restart: forceRefresh=true fetches fresh data
  /// - Only metadata (lastModified, eTag) cached for conditional requests
  /// - Saves bandwidth: 304 responses are ~1KB vs full address list (10-50KB)
  @override
  Future<AddressListResponse?> getAddressList({
    bool forceRefresh = false,
  }) async {
    try {
      // Get cached metadata (NOT address data)
      final cachedMetadata = await _localDataSource.getCachedAddressList();

      // Log cache state
      if (cachedMetadata != null && !forceRefresh) {
        final now = DateTime.now();
        final cacheAge = now.difference(cachedMetadata.lastSyncedAt);
        developer.log(
          'AddressList: Metadata age ${cacheAge.inSeconds}s (TTL ${cacheTTL.inSeconds}s)',
          name: 'AddressRepo',
        );
      }

      // Always fetch from API (only metadata prevents re-download on 304)
      final remoteResponse = await _remoteDataSource.fetchAddressList(
        ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
        ifModifiedSince: forceRefresh ? null : cachedMetadata?.lastModified,
      );

      final now = DateTime.now();

      // 304 Not Modified - data unchanged on server
      if (remoteResponse == null) {
        developer.log(
          'AddressList: 304 Not Modified (no UI refresh)',
          name: 'AddressRepo',
        );

        // Update lastSyncedAt to refresh TTL
        if (cachedMetadata != null) {
          await _localDataSource.cacheAddressListWithMetadata(
            cachedMetadata.copyWith(lastSyncedAt: now),
          );
        }

        // Return null - controller won't update state/UI
        return null;
      }

      // 200 OK - new data from server
      developer.log(
        'AddressList: 200 OK (UI will refresh)',
        name: 'AddressRepo',
      );

      // Save ONLY metadata (lastModified, eTag) to Hive
      // Address data is in Riverpod state (in-memory), not persistent
      final newCacheDto = AddressCacheDto(
        lastSyncedAt: now,
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse.lastModified,
      );

      await _localDataSource.cacheAddressListWithMetadata(newCacheDto);

      return remoteResponse.addressList.toDomain();
    } catch (e) {
      developer.log('AddressList: Error - $e', name: 'AddressRepo');

      rethrow;
    }
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
    double? latitude,
    double? longitude,
    required String addressType,
  }) async {
    try {
      final addressDto = await _remoteDataSource.createAddress(
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
      return addressDto.toDomain();
    } catch (e) {
      rethrow;
    }
  }

  @override
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
  }) async {
    try {
      final addressDto = await _remoteDataSource.updateAddress(
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
      return addressDto.toDomain();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(int id) async {
    try {
      await _remoteDataSource.deleteAddress(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Address> selectAddress(int id) async {
    try {
      final addressDto = await _remoteDataSource.selectAddress(id);
      return addressDto.toDomain();
    } catch (e) {
      rethrow;
    }
  }
}
