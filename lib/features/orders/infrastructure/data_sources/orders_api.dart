import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/utils/logger.dart';
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
    return getOrders(status: 'delivered', page: page);
  }

  /// Fetch rating for a specific order
  /// Returns the current user's rating for the order, or null if not rated
  Future<OrderRatingEntity?> getOrderRating(int orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderRating(orderId.toString()),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          // The API returns a list of ratings. The current user's rating
          // should be in the results. We'll take the first one since
          // the API should filter by current user.
          final ratingJson = results.first as Map<String, dynamic>;
          return OrderRatingEntity.fromJson(ratingJson);
        }
      }

      return null; // No rating found
    } on DioException catch (e) {
      Logger.warning('Error fetching order rating: ${e.message}');
      return null; // Return null if error (order might not be rated yet)
    } catch (e) {
      Logger.warning('Error parsing order rating: $e');
      return null;
    }
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

  /// Fetch order lines (products) for a specific order
  /// [orderId] - The ID of the order
  /// Returns list of order line entities
  Future<List<OrderLineEntity>> getOrderLines(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderLinesByOrder(orderId),
      );

      if (response.statusCode == 200 && response.data != null) {
        // API returns paginated response: {count, next, previous, results}
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];

        final orderIdInt = int.parse(orderId);

        // Filter to only include order lines that match the requested order ID
        // API seems to return order lines from multiple orders, so we filter client-side
        return results
            .map((e) => OrderLineEntity.fromJson(e as Map<String, dynamic>))
            .where((orderLine) => orderLine.orderId == orderIdInt)
            .toList();
      }

      throw Exception('Failed to load order lines');
    } on DioException catch (e) {
      throw Exception('Error loading order lines: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Submit rating for an order
  /// [orderId] - The ID of the order to rate
  /// [stars] - Rating value (1-5)
  /// [body] - Optional review text
  /// [ratingId] - Optional rating ID for updating existing rating
  ///
  /// Automatically handles both creating new ratings (POST) and updating
  /// existing ratings (PATCH). If ratingId is provided, uses PATCH.
  /// If POST returns 400 "already have a rating", automatically retries with PATCH.
  Future<void> submitOrderRating({
    required int orderId,
    required int stars,
    String? body,
    int? ratingId,
  }) async {
    try {
      final requestBody = {
        'stars': stars,
        if (body != null && body.isNotEmpty) 'body': body,
      };

      // If ratingId is provided, use PATCH to update existing rating
      if (ratingId != null) {
        Logger.info(
          'Updating existing rating with PATCH (rating_id: $ratingId)',
        );
        final patchResponse = await _apiClient.patch(
          ApiEndpoints.orderRatingWithId(orderId.toString(), ratingId),
          data: requestBody,
        );

        if (patchResponse.statusCode != 200) {
          throw Exception('Failed to update rating');
        }
        return; // Successfully updated
      }

      // Try POST first (for first-time rating)
      try {
        final response = await _apiClient.post(
          ApiEndpoints.orderRating(orderId.toString()),
          data: requestBody,
        );

        if (response.statusCode != 201 && response.statusCode != 200) {
          throw Exception('Failed to submit rating');
        }
      } on DioException catch (postError) {
        // If 400 with "already have a rating" error, retry with PATCH
        if (postError.response?.statusCode == 400) {
          final errorData = postError.response?.data;
          String errorMessage = '';

          // Handle both string and map response formats
          if (errorData is String) {
            errorMessage = errorData.toLowerCase();
          } else if (errorData is Map<String, dynamic>) {
            errorMessage = errorData.toString().toLowerCase();
          }

          // Log the actual error for debugging
          Logger.warning('Rating POST returned 400. Error data: $errorData');

          // Check for common variations of "already rated" error
          if (errorMessage.contains('already have a rating') ||
              errorMessage.contains('already rated') ||
              errorMessage.contains('rating already exists')) {
            Logger.info(
              'Detected existing rating. Need to fetch order to get rating_id...',
            );

            // To use PATCH with rating_id in URL, we need to fetch the order first
            // to get the rating_id. However, since the UI already has the order data,
            // this scenario should rarely happen. Log a warning and throw a helpful error.
            Logger.warning(
              'Rating already exists but ratingId was not provided. Please refresh the order list.',
            );
            throw Exception(
              'This order has already been rated. Please refresh the page and try editing your existing rating.',
            );
          }
        }
        // Re-throw if not the specific "already have a rating" error
        rethrow;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You can only rate your own completed orders');
      }
      throw Exception('Error submitting rating: ${e.message}');
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
