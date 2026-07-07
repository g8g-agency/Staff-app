// lib/features/orders/presentation/state/active_order_notifier.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/uuid.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../tables/providers/tables_providers.dart';
import '../../domain/entities/menu_product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../providers/orders_providers.dart';

part 'active_order_notifier.g.dart';

@riverpod
class ActiveOrderNotifier extends _$ActiveOrderNotifier {
  StreamSubscription<List<Order>>? _subscription;

  @override
  FutureOr<Order?> build(String tableId) async {
    final repository = ref.watch(ordersRepositoryProvider);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Watch all active orders and filter for this table
    _subscription = repository.watchActiveOrders().listen((orders) {
      Order? draftOrder;
      Order? latestActiveOrder;
      for (final o in orders) {
        if (o.tableId == tableId) {
          if (o.status == OrderStatus.draft) {
            draftOrder = o;
          } else {
            if (latestActiveOrder == null || o.createdAt.isAfter(latestActiveOrder.createdAt)) {
              latestActiveOrder = o;
            }
          }
        }
      }
      state = AsyncData(draftOrder ?? latestActiveOrder);
    });

    // Initial load from cache
    return repository.getActiveOrderForTable(tableId);
  }

  Future<void> createOrder() async {
    final repository = ref.read(ordersRepositoryProvider);
    final updateTableStatus = ref.read(updateTableStatusUseCaseProvider);

    final newOrder = Order(
      id: UuidGenerator.generateV4(),
      tableId: tableId,
      items: const [],
      status: OrderStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save order
    await repository.saveOrder(newOrder);
    
    // Update table status to occupied and bind order ID
    await updateTableStatus(tableId, TableStatus.occupied, orderId: newOrder.id);
    
    state = AsyncData(newOrder);
  }

  Future<void> addItem(MenuProduct product, int seatNumber, List<ModifierOption> modifiers) async {
    var order = state.value;
    final repository = ref.read(ordersRepositoryProvider);

    // If order is null or already sent/delivered/etc, create a new draft order session
    if (order == null || order.status != OrderStatus.draft) {
      order = Order(
        id: UuidGenerator.generateV4(),
        tableId: tableId,
        items: const [],
        status: OrderStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.saveOrder(order);
    }

    final items = List<OrderItem>.from(order.items);
    
    // Check if item with same product, seat and modifiers already exists
    final index = items.indexWhere((i) {
      if (i.product.id != product.id || i.seatNumber != seatNumber) return false;
      if (i.selectedModifiers.length != modifiers.length) return false;
      // Compare elements of modifiers list
      final modIds = modifiers.map((m) => m.id).toSet();
      final itemModIds = i.selectedModifiers.map((m) => m.id).toSet();
      return modIds.difference(itemModIds).isEmpty;
    });

    if (index != -1) {
      // Increment quantity
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      // Add new item
      items.add(OrderItem(
        id: UuidGenerator.generateV4(),
        product: product,
        quantity: 1,
        selectedModifiers: modifiers,
        seatNumber: seatNumber,
        status: OrderItemStatus.queued,
      ));
    }

    final updated = order.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    state = AsyncData(updated);
  }

  Future<void> updateItemQuantity(String itemId, int newQuantity) async {
    final order = state.value;
    if (order == null) return;

    final repository = ref.read(ordersRepositoryProvider);

    final items = List<OrderItem>.from(order.items);
    final index = items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    if (newQuantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: newQuantity);
    }

    final updated = order.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    state = AsyncData(updated);
  }

  Future<void> sendToKitchen() async {
    final order = state.value;
    if (order == null) return;

    final repository = ref.read(ordersRepositoryProvider);

    // Transition all items status to queued (draft items now active)
    final items = order.items.map((item) {
      return item.copyWith(status: OrderItemStatus.queued);
    }).toList();

    final updated = order.copyWith(
      items: items,
      status: OrderStatus.sent,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    state = AsyncData(updated);
  }

  Future<void> payAndComplete() async {
    final order = state.value;
    if (order == null) return;

    final repository = ref.read(ordersRepositoryProvider);
    final updateTableStatus = ref.read(updateTableStatusUseCaseProvider);

    final updated = order.copyWith(
      status: OrderStatus.completed,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    
    // Update table status to cleaning, clear active order
    await updateTableStatus(tableId, TableStatus.cleaning, orderId: null);
    
    state = const AsyncData(null);
  }

  Future<void> clearAlert() async {
    final updateTableStatus = ref.read(updateTableStatusUseCaseProvider);
    await updateTableStatus(tableId, TableStatus.occupied);
  }

  Future<void> assignWaiter(String name) async {
    final order = state.value;
    if (order == null) return;

    final repository = ref.read(ordersRepositoryProvider);
    final updated = order.copyWith(
      waiterName: name,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    state = AsyncData(updated);
  }

  Future<void> cancelItem(String itemId, String reason) async {
    final order = state.value;
    if (order == null) return;

    final repository = ref.read(ordersRepositoryProvider);
    final items = List<OrderItem>.from(order.items);
    final index = items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = items[index];
    items[index] = item.copyWith(status: OrderItemStatus.cancelled);

    final log = 'Cancelled ${item.quantity}x ${item.product.name} (Seat ${item.seatNumber}): $reason';
    final cancelLogs = List<String>.from(order.cancelLogs)..add(log);

    final updated = order.copyWith(
      items: items,
      cancelLogs: cancelLogs,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
    state = AsyncData(updated);
  }
}
