import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/cache_config.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/category_product_repository.dart';
import '../data_sources/local/category_local_data_source.dart';
import '../data_sources/local/category_product_local_data_source.dart';
import '../data_sources/remote/category_remote_data_source.dart';
import '../data_sources/remote/category_product_remote_data_source.dart';
import '../repositories/category_repository_impl.dart';
import '../repositories/category_product_repository_impl.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSource();
});

final categoryRemoteDataSourceProvider =
    Provider<CategoryRemoteDataSource>((ref) {
      return CategoryRemoteDataSource(ref.watch(apiClientProvider));
    });

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    localDataSource: ref.watch(categoryLocalDataSourceProvider),
    remoteDataSource: ref.watch(categoryRemoteDataSourceProvider),
    cacheTtl: CacheConfig.cacheTTL,
  );
});

final categoryProductLocalDataSourceProvider =
    Provider<CategoryProductLocalDataSource>((ref) {
      return CategoryProductLocalDataSource();
    });

final categoryProductRemoteDataSourceProvider =
    Provider<CategoryProductRemoteDataSource>((ref) {
      return CategoryProductRemoteDataSource(ref.watch(apiClientProvider));
    });

final categoryProductRepositoryProvider =
    Provider<CategoryProductRepository>((ref) {
      return CategoryProductRepositoryImpl(
        localDataSource: ref.watch(categoryProductLocalDataSourceProvider),
        remoteDataSource: ref.watch(categoryProductRemoteDataSourceProvider),
        cacheTtl: CacheConfig.cacheTTL,
      );
    });
