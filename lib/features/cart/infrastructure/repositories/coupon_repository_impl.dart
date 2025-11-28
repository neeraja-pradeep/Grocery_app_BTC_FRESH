import 'dart:developer' as developer;
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../data_sources/local/coupon_local_data_source.dart';
import '../data_sources/local/coupon_cache_dto.dart';
import '../data_sources/remote/coupon_remote_data_source.dart';

/// Implementation of CouponRepository
/// Combines local cache and remote API with HTTP conditional headers support
class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl({
    required CouponLocalDataSource localDataSource,
    required CouponRemoteDataSource remoteDataSource,
    this.cacheTTL = const Duration(hours: 1),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final CouponLocalDataSource _localDataSource;
  final CouponRemoteDataSource _remoteDataSource;
  final Duration cacheTTL;
  @override
  Future<CouponListResponse?> getCouponList({bool forceRefresh = false}) async {
    try {
      // Get cached metadata (NOT coupon data)
      final cachedMetadata = await _localDataSource.getCachedCouponList();

      // Log cache state
      if (cachedMetadata != null && !forceRefresh) {
        final now = DateTime.now();
        final cacheAge = now.difference(cachedMetadata.lastSyncedAt);
        developer.log(
          'CouponList: Metadata age ${cacheAge.inSeconds}s (TTL ${cacheTTL.inSeconds}s)',
          name: 'CouponRepo',
        );
      }

      // Always fetch from API (only metadata prevents re-download on 304)
      final remoteResponse = await _remoteDataSource.fetchCouponList(
        ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
        ifModifiedSince: forceRefresh ? null : cachedMetadata?.lastModified,
      );

      final now = DateTime.now();

      // 304 Not Modified - data unchanged on server
      if (remoteResponse == null) {
        developer.log(
          'CouponList: 304 Not Modified (no UI refresh)',
          name: 'CouponRepo',
        );

        // Update lastSyncedAt to refresh TTL
        if (cachedMetadata != null) {
          await _localDataSource.cacheCouponListWithMetadata(
            cachedMetadata.copyWith(lastSyncedAt: now),
          );
        }

        // Return null - controller won't update state/UI
        return null;
      }

      // 200 OK - new data from server
      developer.log('CouponList: 200 OK (UI will refresh)', name: 'CouponRepo');

      // Save ONLY metadata (lastModified, eTag) to Hive
      // Coupon data is in Riverpod state (in-memory), not persistent
      final newCacheDto = CouponCacheDto(
        lastSyncedAt: now,
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse.lastModified,
      );

      await _localDataSource.cacheCouponListWithMetadata(newCacheDto);

      return remoteResponse.couponList.toDomain();
    } catch (e) {
      developer.log('CouponList: Error - $e', name: 'CouponRepo');

      rethrow;
    }
  }
}
