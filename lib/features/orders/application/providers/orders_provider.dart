import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order_entity.dart';
import '../../infrastructure/data_sources/orders_api.dart';

/// State for orders
class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;
  final String? errorMessage;
  final String? activeFilter; // 'all', 'active', 'pending', 'completed'

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeFilter = 'all',
  });

  OrdersState copyWith({
    List<OrderEntity>? orders,
    bool? isLoading,
    String? errorMessage,
    String? activeFilter,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  bool get hasData => orders.isNotEmpty;
  bool get isEmpty => orders.isEmpty && !isLoading;

  List<OrderEntity> get activeOrders =>
      orders.where((o) => o.isActive).toList();

  List<OrderEntity> get pendingOrders =>
      orders.where((o) => o.isPending).toList();

  List<OrderEntity> get completedOrders =>
      orders.where((o) => o.isCompleted).toList();
}

/// Orders notifier for managing order state
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersApi _ordersApi;

  OrdersNotifier(this._ordersApi) : super(const OrdersState());

  /// Fetch all orders
  Future<void> fetchOrders({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeFilter: status ?? 'all',
    );

    try {
      final orders = await _ordersApi.getOrders(status: status);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Fetch active orders
  Future<void> fetchActiveOrders() async {
    await fetchOrders(status: 'active');
  }

  /// Fetch pending orders
  Future<void> fetchPendingOrders() async {
    await fetchOrders(status: 'pending');
  }

  /// Fetch completed orders (for Previous tab)
  /// Uses status='delivered' to fetch all delivered/completed orders
  /// Also fetches ratings for each completed order
  Future<void> fetchCompletedOrders() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeFilter: 'delivered',
    );

    try {
      // Fetch completed orders
      final orders = await _ordersApi.getOrders(status: 'delivered');

      // Fetch ratings for each order and update the order objects
      final ordersWithRatings = await Future.wait(
        orders.map((order) async {
          // Fetch rating for this order
          final rating = await _ordersApi.getOrderRating(order.id);

          // If rating exists, create a new OrderEntity with the rating
          if (rating != null) {
            return OrderEntity(
              id: order.id,
              status: order.status,
              totalAmount: order.totalAmount,
              createdAt: order.createdAt,
              updatedAt: order.updatedAt,
              orderLines: order.orderLines,
              deliveryAddress: order.deliveryAddress,
              rating: rating, // Add the fetched rating
            );
          }

          return order; // Return order as-is if no rating found
        }),
      );

      state = state.copyWith(orders: ordersWithRatings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Refresh orders
  Future<void> refresh() async {
    final currentFilter = state.activeFilter;
    await fetchOrders(status: currentFilter == 'all' ? null : currentFilter);
  }
}

/// Provider for OrdersNotifier
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final ordersApi = ref.watch(ordersApiProvider);
  return OrdersNotifier(ordersApi);
});

/// Provider for order details
final orderDetailsProvider = FutureProvider.family<OrderEntity, String>((
  ref,
  orderId,
) async {
  final ordersApi = ref.watch(ordersApiProvider);
  return ordersApi.getOrderDetails(orderId);
});
