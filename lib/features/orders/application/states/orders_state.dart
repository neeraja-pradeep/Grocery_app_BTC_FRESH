import '../../domain/entities/order_entity.dart';

class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;
  final String? errorMessage;
  // Tracks the last-fetched status so refresh() can repeat the same query.
  final String? activeFilter;

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
}
