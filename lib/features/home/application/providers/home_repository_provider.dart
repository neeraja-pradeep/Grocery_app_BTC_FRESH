import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/repositories/home_repository.dart';
import '../../infrastructure/data_sources/local/home_local_ds.dart';
import '../../infrastructure/data_sources/remote/home_api.dart';
import '../../infrastructure/repositories/home_repostory_impl.dart';

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSourceImpl(Boxes.homeDataBox);
});

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeApiImpl(apiClient);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remoteDs = ref.watch(homeRemoteDataSourceProvider);
  final localDs = ref.watch(homeLocalDataSourceProvider);
  return HomeRepositoryImpl(remoteDataSource: remoteDs, localDataSource: localDs);
});
