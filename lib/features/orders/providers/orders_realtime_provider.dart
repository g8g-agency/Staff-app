// lib/features/orders/providers/orders_realtime_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/state/auth_notifier.dart';
import '../../alerts/services/order_alert_service.dart';
import '../presentation/state/order_alert_notifier.dart';
import '../services/orders_realtime_service.dart';
import 'orders_providers.dart';
import '../presentation/state/orders_projection_provider.dart';

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

  /// Directly queries Supabase for the order and its items, then enriches the alert.
  /// This bypasses the projection chain and avoids race conditions.
  Future<void> enrichAlertFromProjection(String orderId) async {
    // Give the DB 1.5s to finish writing order_items after the order INSERT
    await Future.delayed(const Duration(milliseconds: 1500));

    Future<bool> tryEnrich() async {
      try {
        // Direct query: order + order_items + table label in one call
        final orderRow = await supabase
            .from('orders')
            .select('table_id, order_items(id, name, qty, unit_price)')
            .eq('id', orderId)
            .maybeSingle();

        if (orderRow == null) return false;

        final rawItems = orderRow['order_items'] as List? ?? [];
        if (rawItems.isEmpty) return false; // items not yet inserted — retry

        final items = rawItems.cast<Map<String, dynamic>>();

        // Resolve table label
        final tableId = orderRow['table_id'] as String? ?? '';
        String tableLabel = tableId;
        if (tableId.isNotEmpty) {
          final tableRow = await supabase
              .from('tables')
              .select('display_name, table_number')
              .eq('id', tableId)
              .maybeSingle();
          if (tableRow != null) {
            tableLabel = (tableRow['display_name'] ?? tableRow['table_number'] ?? tableId).toString();
          }
        }

        // unit_price is stored in rupees → convert to paise (minor units)
        final totalMinor = items.fold<int>(0, (sum, item) {
          final unitPriceRupees = (item['unit_price'] as num? ?? 0).toDouble();
          final qty = (item['qty'] as num? ?? 1).toInt();
          return sum + (unitPriceRupees * 100 * qty).round();
        });

        final alertItems = items
            .map((item) => <String, dynamic>{
                  'name': item['name'] ?? 'Item',
                  'quantity': item['qty'] ?? 1,
                })
            .toList();

        orderAlertNotifier.enrichAlert(
          orderId: orderId,
          tableLabel: tableLabel,
          itemCount: items.length,
          totalAmountMinor: totalMinor,
          items: alertItems,
        );
        debugPrint('[ordersRealtimeProvider] Enriched order $orderId — ${items.length} items, total: $totalMinor paise, table: $tableLabel');
        return true;
      } catch (e) {
        debugPrint('[ordersRealtimeProvider] enrichAlert error for $orderId: $e');
        return false;
      }
    }

    final success = await tryEnrich();
    if (!success) {
      // Retry once more after 2s in case order_items weren't written yet
      debugPrint('[ordersRealtimeProvider] Retrying enrich for $orderId in 2s...');
      await Future.delayed(const Duration(seconds: 2));
      await tryEnrich();
    }
  }


  service.onEvent.listen((event) {
    debugPrint('[ordersRealtimeProvider] EVENT: type=${event.type}, status=${event.payload['status']}');
    if (event.type == RealtimeOrderEventType.insert) {
      alertService.playNewOrderAlert();
      orderAlertNotifier.enqueueAlert(event.payload);
      final orderId = (event.payload['id'] ?? event.payload['orderId'])?.toString() ?? '';
      if (orderId.isNotEmpty) {
        enrichAlertFromProjection(orderId);
      } else {
        fetchAndUpdate();
      }
    } else if (event.type == RealtimeOrderEventType.update) {
      final status = event.payload['status'];
      if (status == 'ready' || status == 'READY') {
        final orderId = event.payload['id']?.toString() ?? '';
        // Only show the ready popup to the waiter who accepted this order.
        // We track accepted orders locally in _myAcceptedOrderIds.
        final isMyOrder = orderId.isNotEmpty
            ? orderAlertNotifier.isMyAcceptedOrder(orderId)
            : true; // no ID → fallback to showing

        if (isMyOrder) {
          debugPrint('[ordersRealtimeProvider] Ready alert for MY order $orderId — showing popup.');
          alertService.playOrderReadyAlert();
          orderAlertNotifier.enqueueReadyAlert(event.payload);
        } else {
          debugPrint('[ordersRealtimeProvider] Ready alert for order $orderId — not mine, skipping.');
        }
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
