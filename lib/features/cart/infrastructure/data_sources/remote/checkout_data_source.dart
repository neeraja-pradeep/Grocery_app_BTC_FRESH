import '../../../../../core/network/api_client.dart';
import '../../models/checkout_model.dart';

class CheckoutDataSource {
  final ApiClient _apiClient;

  CheckoutDataSource(this._apiClient);

  Future<CheckoutModel> createCheckout(DateTime createdAt) async {
    final response = await _apiClient.post(
      '/api/order/v1/checkouts/',
      data: {'created_at': createdAt.toIso8601String()},
    );

    return CheckoutModel.fromJson(response.data);
  }

  /// Optional – list all checkouts (if needed)
  Future<List<CheckoutModel>> getAllCheckouts() async {
    final response = await _apiClient.get('/api/order/v1/checkouts/');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['results'] as List;
    return data.map((e) => CheckoutModel.fromJson(e)).toList();
  }
}
