import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/features/cart/domain/repositories/checkout_repository.dart';
import 'package:grocery_app/features/cart/infrastructure/data_sources/remote/checkout_data_source.dart';

final checkoutDataSourceProvider = Provider<CheckoutDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckoutDataSource(apiClient);
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final dataSource = ref.watch(checkoutDataSourceProvider);
  return CheckoutRepository(dataSource);
});
