import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/address_repository.dart';
import '../data_sources/local/address_local_data_source.dart';
import '../data_sources/remote/address_remote_data_source.dart';
import '../repositories/address_repository_impl.dart';

/// Local data source provider
final addressLocalDataSourceProvider = Provider<AddressLocalDataSource>((ref) {
  return AddressLocalDataSourceImpl();
});

/// Remote data source provider
final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressRemoteDataSourceImpl(apiClient);
});

/// Repository provider
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final localDataSource = ref.watch(addressLocalDataSourceProvider);
  final remoteDataSource = ref.watch(addressRemoteDataSourceProvider);

  return AddressRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});
