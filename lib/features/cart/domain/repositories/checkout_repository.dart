import '../../infrastructure/data_sources/remote/checkout_data_source.dart';

import '../../domain/entities/checkout.dart';

class CheckoutRepository {
  final CheckoutDataSource _dataSource;

  CheckoutRepository(this._dataSource);

  Future<Checkout> createCheckout() async {
    final now = DateTime.now().toUtc();
    return await _dataSource.createCheckout(now);
  }

  Future<List<Checkout>> getAllCheckouts() async {
    return await _dataSource.getAllCheckouts();
  }
}
