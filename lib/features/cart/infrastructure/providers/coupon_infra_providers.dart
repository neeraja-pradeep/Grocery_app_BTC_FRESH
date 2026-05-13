import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../data_sources/local/coupon_local_data_source.dart';
import '../data_sources/remote/coupon_remote_data_source.dart';
import '../repositories/coupon_repository_impl.dart';

/// Local data source provider
final couponLocalDataSourceProvider = Provider<CouponLocalDataSource>((ref) {
  return CouponLocalDataSourceImpl();
});

/// Remote data source provider
final couponRemoteDataSourceProvider = Provider<CouponRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CouponRemoteDataSourceImpl(apiClient);
});

/// Repository provider
final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  final localDataSource = ref.watch(couponLocalDataSourceProvider);
  final remoteDataSource = ref.watch(couponRemoteDataSourceProvider);

  return CouponRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});
