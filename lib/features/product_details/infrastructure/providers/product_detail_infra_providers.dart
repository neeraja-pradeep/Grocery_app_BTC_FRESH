import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../data_sources/local/product_detail_local_data_source.dart';
import '../data_sources/remote/product_detail_remote_data_source.dart';
import '../repositories/product_detail_repository_impl.dart';

/// Local data source provider
final productDetailLocalDataSourceProvider =
    Provider<ProductDetailLocalDataSource>((ref) {
  return ProductDetailLocalDataSourceImpl();
});

/// Remote data source provider
final productDetailRemoteDataSourceProvider =
    Provider<ProductDetailRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductDetailRemoteDataSourceImpl(apiClient);
});

/// Repository provider
final productDetailRepositoryProvider = Provider<ProductDetailRepository>((
  ref,
) {
  final localDataSource = ref.watch(productDetailLocalDataSourceProvider);
  final remoteDataSource = ref.watch(productDetailRemoteDataSourceProvider);

  return ProductDetailRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});
