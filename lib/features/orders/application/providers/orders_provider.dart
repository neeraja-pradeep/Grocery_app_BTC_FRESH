import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/order_entity.dart';
import '../../infrastructure/data_sources/orders_api.dart';
import '../states/orders_state.dart';

export '../states/orders_state.dart';

/// Internal provider — only referenced within this feature's application layer.
/// Presentation files must not import orders_api.dart directly.
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersApi(apiClient);
});

/// Orders notifier for managing order state.
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersApi _ordersApi;

  OrdersNotifier(this._ordersApi) : super(const OrdersState());

  /// Fetch all orders with optional status filter.
  /// The orders list endpoint does not currently embed `order_lines` or a
  /// count, so the card shows "0 Items" unless we hydrate per-order from
  /// `/api/order/v1/order-lines/?order={id}`. The fanout runs in parallel.
  Future<void> fetchOrders({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeFilter: status ?? 'all',
    );

    try {
      final orders = await _ordersApi.getOrders(status: status);
      final hydrated = await Future.wait(orders.map(_hydrateWithLines));
      state = state.copyWith(orders: hydrated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Fetch active orders.
  Future<void> fetchActiveOrders() async {
    await fetchOrders(status: 'active');
  }

  /// Fetch completed orders for the Previous tab.
  /// Ratings are fetched per-order with a 5-second per-call timeout so that
  /// a single slow rating endpoint never blocks the whole list.
  Future<void> fetchCompletedOrders() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeFilter: 'delivered',
    );

    try {
      final orders = await _ordersApi.getOrders(status: 'delivered');

      // Per order, fetch lines + rating in parallel with per-call timeouts.
      // Worst case: 5s for the slowest order's slowest call.
      final hydrated = await Future.wait(
        orders.map((order) async {
          final lines = await _fetchLinesSafely(order);
          final rating = await _ordersApi
              .getOrderRating(order.id)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => null,
              );

          return OrderEntity(
            id: order.id,
            status: order.status,
            totalAmount: order.totalAmount,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            orderLines: lines,
            deliveryAddress: order.deliveryAddress,
            orderlinesCount: lines.length,
            rating: rating ?? order.rating,
          );
        }),
      );

      state = state.copyWith(orders: hydrated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Calls `/api/order/v1/order-lines/?order={id}` and returns a new
  /// OrderEntity with `orderLines` populated and `orderlinesCount` updated.
  /// Skips the call when the orders-list payload already included a count
  /// (so a future backend change embedding the field costs nothing here).
  Future<OrderEntity> _hydrateWithLines(OrderEntity order) async {
    if (order.orderlinesCount > 0) return order;

    final lines = await _fetchLinesSafely(order);
    if (lines.isEmpty) return order;

    return OrderEntity(
      id: order.id,
      status: order.status,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      orderLines: lines,
      deliveryAddress: order.deliveryAddress,
      orderlinesCount: lines.length,
      rating: order.rating,
    );
  }

  /// Wrapper that swallows timeouts/errors so a single bad row never breaks
  /// the whole orders list — returns an empty list instead.
  Future<List<OrderLineEntity>> _fetchLinesSafely(OrderEntity order) async {
    try {
      return await _ordersApi
          .getOrderLines(order.id.toString())
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => const <OrderLineEntity>[],
          );
    } catch (_) {
      return const <OrderLineEntity>[];
    }
  }

  /// Re-fetch using the last known filter.
  Future<void> refresh() async {
    final currentFilter = state.activeFilter;
    await fetchOrders(status: currentFilter == 'all' ? null : currentFilter);
  }

  /// Fetch the line-items for a given order.
  /// Used by the reorder flow in the presentation layer.
  Future<List<OrderLineEntity>> getOrderLines(String orderId) {
    return _ordersApi.getOrderLines(orderId);
  }

  /// Submit or update a star rating for a completed order.
  /// Providing [ratingId] issues a PATCH (update); omitting it issues a POST (create).
  /// Refreshes the completed orders list after a successful submission.
  Future<void> submitRating({
    required int orderId,
    required int stars,
    String? body,
    int? ratingId,
  }) async {
    await _ordersApi.submitOrderRating(
      orderId: orderId,
      stars: stars,
      body: body,
      ratingId: ratingId,
    );
    await fetchCompletedOrders();
  }
}

/// Provider for OrdersNotifier.
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final ordersApi = ref.watch(ordersApiProvider);
  return OrdersNotifier(ordersApi);
});

/// Per-order detail provider.
/// autoDispose ensures instances are released when the viewing widget disposes,
/// preventing unbounded memory growth for family providers keyed on order IDs.
final orderDetailsProvider =
    FutureProvider.autoDispose.family<OrderEntity, String>((
  ref,
  orderId,
) async {
  final ordersApi = ref.watch(ordersApiProvider);
  return ordersApi.getOrderDetails(orderId);
});
