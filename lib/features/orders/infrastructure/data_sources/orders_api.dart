import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/order_entity.dart';

/// Data source for orders API calls
class OrdersApi {
  final ApiClient _apiClient;

  OrdersApi(this._apiClient);

  /// Fetch all orders with optional status filter
  /// [status] can be 'active', 'pending', 'completed', 'cancelled'
  Future<List<OrderEntity>> getOrders({String? status, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (status != null) 'status': status,
      };

      final response = await _apiClient.get(
        ApiEndpoints.orders,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];

        return results
            .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to load orders');
    } on DioException catch (e) {
      throw Exception('Error loading orders: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch active orders
  Future<List<OrderEntity>> getActiveOrders({int page = 1}) async {
    return getOrders(status: 'active', page: page);
  }

  /// Fetch pending orders
  Future<List<OrderEntity>> getPendingOrders({int page = 1}) async {
    return getOrders(status: 'pending', page: page);
  }

  /// Fetch completed orders
  Future<List<OrderEntity>> getCompletedOrders({int page = 1}) async {
    return getOrders(status: 'completed', page: page);
  }

  /// Fetch order details by ID
  Future<OrderEntity> getOrderDetails(String orderId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.orderDetails(orderId));

      if (response.statusCode == 200 && response.data != null) {
        return OrderEntity.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to load order details');
    } on DioException catch (e) {
      throw Exception('Error loading order details: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for OrdersApi
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersApi(apiClient);
});
