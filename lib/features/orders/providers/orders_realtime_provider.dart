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
  }

  service.onEvent.listen((event) {
    debugPrint('[ordersRealtimeProvider] EVENT RECEIVED: type=${event.type}, status=${event.payload['status']}, payload=${event.payload}');
    if (event.type == RealtimeOrderEventType.insert) {
      alertService.playNewOrderAlert();
      orderAlertNotifier.enqueueAlert(event.payload);
      fetchAndUpdate();
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
