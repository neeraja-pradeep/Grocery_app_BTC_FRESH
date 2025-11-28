import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/features/cart/infrastructure/models/checkout_model.dart';

class CheckoutDataSource {
  final ApiClient _apiClient;

  CheckoutDataSource(this._apiClient);

  Future<CheckoutModel> createCheckout(DateTime createdAt) async {
    final response = await _apiClient.post(
      '/api/order/checkouts/',
      data: {'created_at': createdAt.toIso8601String()},
    );

    return CheckoutModel.fromJson(response.data);
  }

  /// Optional – list all checkouts (if needed)
  Future<List<CheckoutModel>> getAllCheckouts() async {
    final response = await _apiClient.get('/api/order/checkouts/');
    final data = response.data['results'] as List;
    return data.map((e) => CheckoutModel.fromJson(e)).toList();
  }
}
