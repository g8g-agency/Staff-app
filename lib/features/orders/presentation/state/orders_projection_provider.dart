// lib/features/orders/presentation/state/orders_projection_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';

class OrdersProjectionNotifier extends StateNotifier<List<Order>> {
  OrdersProjectionNotifier() : super([]);

  /// Updates the in-memory projection with active orders only.
  /// Completed and cancelled orders are always evicted immediately —
  /// this prevents stale floor-card data after checkout.
  void updateProjection(List<Order> orders) {
    final active = orders
        .where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .toList();
    state = List.unmodifiable(active);
  }

  void clearProjection() {
    state = [];
  }
}

final ordersProjectionProvider =
    StateNotifierProvider<OrdersProjectionNotifier, List<Order>>((ref) {
  return OrdersProjectionNotifier();
});
