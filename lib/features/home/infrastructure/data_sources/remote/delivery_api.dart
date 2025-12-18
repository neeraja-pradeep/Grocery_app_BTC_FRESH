import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../domain/entities/delivery.dart';

/// Data source for delivery status API calls
class DeliveryApi {
  final ApiClient _apiClient;

  DeliveryApi(this._apiClient);

  /// Fetch delivery status for an order
  /// Returns null if delivery not found (404)
  Future<DeliveryEntity?> getDeliveryStatus(int orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.deliveryStatus(orderId),
      );

      if (response.statusCode == 200 && response.data != null) {
        return DeliveryEntity.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      // Return null for 404 (delivery not yet assigned)
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Error fetching delivery status: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for DeliveryApi
final deliveryApiProvider = Provider<DeliveryApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeliveryApi(apiClient);
});
