import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../infrastructure/data_sources/remote/checkout_data_source.dart';

final checkoutDataSourceProvider = Provider<CheckoutDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckoutDataSource(apiClient);
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final dataSource = ref.watch(checkoutDataSourceProvider);
  return CheckoutRepository(dataSource);
});
