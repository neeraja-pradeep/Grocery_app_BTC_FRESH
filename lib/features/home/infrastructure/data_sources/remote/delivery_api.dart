import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../domain/entities/delivery.dart';

/// Data source for delivery status API calls
class DeliveryApi {
  final ApiClient _apiClient;

  DeliveryApi(this._apiClient);

  /// Fetch delivery status for an order using the correct API response format:
  /// 1. Call: GET /api/delivery/v1/deliveries/?order={order_id}
  ///    Response format: { "count": number, "results": [...] }
  /// 2. Parse delivery from results array
  ///
  /// Returns null if:
  /// - Empty results array (admin hasn't accepted order yet)
  /// - 404 error (delivery not yet created)
  Future<DeliveryEntity?> getDeliveryStatus(int orderId) async {
    try {
      // Fetch deliveries list by order ID
      final response = await _apiClient.get(
        ApiEndpoints.deliveriesByOrder(orderId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Extract results array from paginated response
        final results = responseData['results'] as List<dynamic>?;

        // Empty results means admin hasn't accepted the order yet
        if (results == null || results.isEmpty) {
          return null;
        }

        // Get the first delivery (should only be one per order)
        final deliveryData = results.first as Map<String, dynamic>;

        // Parse and return delivery entity directly from results[0]
        return DeliveryEntity.fromJson(deliveryData);
      }

      return null;
    } on DioException catch (e) {
      // Return null for 404 (delivery not yet created) - NOT an error
      if (e.response?.statusCode == 404) {
        return null;
      }
      // Rethrow other errors
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
