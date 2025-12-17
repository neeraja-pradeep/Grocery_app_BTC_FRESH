import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orders/application/providers/orders_provider.dart';

/// Provider to find the most recent completed order containing a specific product variant
/// Returns (orderId, deliveryDate) tuple if found, null otherwise
final productCompletedOrderProvider =
    Provider.family<({int orderId, String deliveryDate})?, int>((
      ref,
      productVariantId,
    ) {
      final ordersState = ref.watch(ordersProvider);

      // If orders are loading or empty, return null
      if (ordersState.isLoading || ordersState.orders.isEmpty) {
        return null;
      }

      // Filter for completed/delivered orders only
      final completedOrders = ordersState.orders
          .where((order) => order.isCompleted)
          .toList();

      // Sort by most recent first
      completedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Find first order containing this product variant
      for (final order in completedOrders) {
        final hasProduct = order.orderLines.any(
          (line) => line.productVariantId == productVariantId,
        );

        if (hasProduct) {
          // Format delivery date (use updatedAt if available, otherwise createdAt)
          final deliveryDate = order.updatedAt ?? order.createdAt;
          final formattedDate = _formatDeliveryDate(deliveryDate);

          return (orderId: order.id, deliveryDate: formattedDate);
        }
      }

      // No completed order found containing this product
      return null;
    });

/// Format delivery date to readable string (e.g., "Thu, 16 Oct")
String _formatDeliveryDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  final day = date.day;

  return '$weekday, $day $month';
}
