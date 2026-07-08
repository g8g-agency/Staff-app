// lib/features/orders/providers/orders_realtime_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/state/auth_notifier.dart';
import '../../alerts/services/order_alert_service.dart';
import '../presentation/state/order_alert_notifier.dart';
import '../services/orders_realtime_service.dart';
import 'orders_providers.dart';
import '../presentation/state/orders_projection_provider.dart';
import '../../tables/providers/tables_providers.dart';

final orderAlertServiceProvider = Provider<OrderAlertService>((ref) {
  final service = OrderAlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ordersRealtimeProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final staff = authState.loggedInStaff;
  final branch = authState.selectedBranch;

  // Only subscribe if staff is logged in and branch is selected
  if (staff == null || branch == null) {
    return;
  }

  final supabase = Supabase.instance.client;
  final service = OrdersRealtimeService(supabase, branch.id);
  final alertService = ref.read(orderAlertServiceProvider);
  final orderAlertNotifier = ref.read(orderAlertNotifierProvider.notifier);

  Future<void> fetchAndUpdate() async {
    final repo = ref.read(ordersRepositoryProvider);
    final orders = await repo.fetchActiveOrders();
    ref.read(ordersProjectionProvider.notifier).updateProjection(orders);
    return;
  }

  /// After the full order list is fetched, look up the order by ID and
  /// enrich the alert with the real table label, item count, and total.
  Future<void> enrichAlertFromProjection(String orderId) async {
    await fetchAndUpdate();

    // Resolve table label from tables repository
    String tableLabel = 'N/A';
    try {
      final tablesRepo = ref.read(tablesRepositoryProvider);
      final tables = await tablesRepo.getTables();
      // Look at the projection for the order's tableId
      final projection = ref.read(ordersProjectionProvider);
      final order = projection.where((o) => o.id == orderId).firstOrNull;
      if (order != null) {
        final matchingTable = tables.where((t) => t.id == order.tableId).firstOrNull;
        tableLabel = matchingTable?.label ?? order.tableId;

        // Build items list for the alert
        final alertItems = order.items
            .map((item) => <String, dynamic>{
                  'name': item.product.name,
                  'quantity': item.quantity,
                })
            .toList();

        orderAlertNotifier.enrichAlert(
          orderId: orderId,
          tableLabel: tableLabel,
          itemCount: order.items.length,
          totalAmountMinor: order.totalPrice.amountInCents,
          items: alertItems,
        );
      }
    } catch (e) {
      debugPrint('[ordersRealtimeProvider] Failed to enrich alert: $e');
    }
  }

  service.onEvent.listen((event) {
    debugPrint('[ordersRealtimeProvider] EVENT RECEIVED: type=${event.type}, status=${event.payload['status']}, payload=${event.payload}');
    if (event.type == RealtimeOrderEventType.insert) {
      alertService.playNewOrderAlert();
      orderAlertNotifier.enqueueAlert(event.payload);
      // Fetch full order data and enrich the alert with table label, items, and total
      final orderId = (event.payload['id'] ?? event.payload['orderId'])?.toString() ?? '';
      if (orderId.isNotEmpty) {
        enrichAlertFromProjection(orderId);
      } else {
        fetchAndUpdate();
      }
    } else if (event.type == RealtimeOrderEventType.update) {
      final status = event.payload['status'];
      if (status == 'ready' || status == 'READY') {
        alertService.playOrderReadyAlert();
        orderAlertNotifier.enqueueReadyAlert(event.payload);
      }
      fetchAndUpdate();
    }
  });

  // Initial fetch
  fetchAndUpdate();

  service.subscribe();

  ref.onDispose(() {
    service.dispose();
  });
});
