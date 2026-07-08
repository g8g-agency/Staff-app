// lib/features/orders/presentation/state/order_alert_notifier.dart
//
// OrderAlertNotifier — manages the queue of incoming order alerts.
// Exposed as a global Riverpod provider.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_alert_model.dart';
import '../../../../core/network/network_providers.dart';
import '../../services/order_action_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class OrderAlertState {
  final List<IncomingOrderAlert> queue;
  final List<OrderReadyAlert> readyQueue;
  final int totalReceived;
  final int totalAccepted;
  final int totalPassed;
  final int totalExpired;
  final List<Duration> responseTimes;

  final bool hasOverflow;
  final int overflowCount;

  const OrderAlertState({
    this.queue = const [],
    this.readyQueue = const [],
    this.totalReceived = 0,
    this.totalAccepted = 0,
    this.totalPassed = 0,
    this.totalExpired = 0,
    this.responseTimes = const [],
    this.hasOverflow = false,
    this.overflowCount = 0,
  });

  IncomingOrderAlert? get currentAlert =>
      queue.where((a) => a.status == OrderAlertStatus.pending).firstOrNull;

  OrderReadyAlert? get currentReadyAlert => readyQueue.firstOrNull;

  OrderAlertState copyWith({
    List<IncomingOrderAlert>? queue,
    List<OrderReadyAlert>? readyQueue,
    int? totalReceived,
    int? totalAccepted,
    int? totalPassed,
    int? totalExpired,
    List<Duration>? responseTimes,
    bool? hasOverflow,
    int? overflowCount,
  }) {
    return OrderAlertState(
      queue: queue ?? this.queue,
      readyQueue: readyQueue ?? this.readyQueue,
      totalReceived: totalReceived ?? this.totalReceived,
      totalAccepted: totalAccepted ?? this.totalAccepted,
      totalPassed: totalPassed ?? this.totalPassed,
      totalExpired: totalExpired ?? this.totalExpired,
      responseTimes: responseTimes ?? this.responseTimes,
      hasOverflow: hasOverflow ?? this.hasOverflow,
      overflowCount: overflowCount ?? this.overflowCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class OrderAlertNotifier extends StateNotifier<OrderAlertState> {
  final Ref _ref;
  final Map<String, Timer> _timeoutTimers = {};
  bool _disposed = false;

  static const Duration _alertTimeout = Duration(seconds: 30);

  OrderAlertNotifier(this._ref) : super(const OrderAlertState());

  // ── Public API ─────────────────────────────────────────────────────────────

  static const int maxQueueSize = 10;

  /// Called by OperationalRuntimeBridge when an ORDER_ASSIGNED event arrives.
  void enqueueAlert(Map<String, dynamic> payload) {
    final alert = IncomingOrderAlert.fromPayload(payload);

    // Idempotency: don't add duplicate alerts for same orderId
    final existing = state.queue.any((a) => a.orderId == alert.orderId);
    if (existing) {
      debugPrint('[OrderAlert] Duplicate alert for order ${alert.orderId} — ignored.');
      return;
    }

    debugPrint('[OrderAlert] Enqueuing alert for order ${alert.orderId}');

    if (state.queue.length >= maxQueueSize) {
      debugPrint(
        '[OrderAlerts] Queue full ($maxQueueSize) — dropping oldest. '
        'Dropped: ${state.queue.first.orderId}',
      );
      state = state.copyWith(
        queue: [...state.queue.sublist(1), alert],
        totalReceived: state.totalReceived + 1,
        hasOverflow: true,
        overflowCount: state.overflowCount + 1,
      );
    } else {
      state = state.copyWith(
        queue: [...state.queue, alert],
        totalReceived: state.totalReceived + 1,
      );
    }

    // Start 30-second timeout timer
    _startTimeoutTimer(alert);
  }

  /// Enrich an existing queued alert with data resolved from the full order fetch.
  /// Called after fetchAndUpdate() completes to fill in table label, item count, total, and items.
  void enrichAlert({
    required String orderId,
    required String tableLabel,
    required int itemCount,
    required int totalAmountMinor,
    required List<Map<String, dynamic>> items,
  }) {
    final index = state.queue.indexWhere((a) => a.orderId == orderId);
    if (index == -1) return;

    final enriched = state.queue[index].copyWith(
      tableNumber: tableLabel,
      itemCount: itemCount,
      totalAmountMinor: totalAmountMinor,
      items: items.map((i) => AlertOrderItem.fromMap(i)).toList(),
    );

    final newQueue = [...state.queue];
    newQueue[index] = enriched;
    state = state.copyWith(queue: newQueue);
    debugPrint('[OrderAlert] Enriched alert for order $orderId — table: $tableLabel, items: $itemCount, total: $totalAmountMinor');
  }

  void clearOverflow() {
    state = state.copyWith(hasOverflow: false, overflowCount: 0);
  }

  /// Called by OperationalRuntimeBridge when an ORDER_READY_FOR_PICKUP event arrives.
  void enqueueReadyAlert(Map<String, dynamic> payload) {
    final alert = OrderReadyAlert.fromPayload(payload);

    // Idempotency: don't add duplicate ready alerts for same orderId
    final existing = state.readyQueue.any((a) => a.orderId == alert.orderId);
    if (existing) {
      debugPrint('[OrderAlert] Duplicate ready alert for order ${alert.orderId} — ignored.');
      return;
    }

    debugPrint('[OrderAlert] Enqueuing ready alert for order ${alert.orderId}');

    state = state.copyWith(
      readyQueue: [...state.readyQueue, alert],
    );
  }

  void dismissReadyAlert(String orderId) {
    state = state.copyWith(
      readyQueue: state.readyQueue.where((a) => a.orderId != orderId).toList(),
    );
  }

  /// Restore pending alerts from backend on reconnect.
  Future<void> restorePendingAlerts({
    required String branchId,
    required String tenantId,
  }) async {
    try {
      final dio = _ref.read(dioClientProvider);

      final response = await dio.get(
        '/api/v1/orders/alerts/pending',
        queryParameters: {'branchId': branchId},
      );

      if (response.statusCode == 200) {
        final orders = response.data['data']['orders'] as List<dynamic>? ?? [];
        for (final order in orders) {
          final m = order as Map<String, dynamic>;
          // Build a minimal payload from the order record
          enqueueAlert({
            'orderId': m['id'],
            'orderNumber': m['order_number'],
            'tableNumber': m['table_id'], // Will improve with join
            'totalAmountMinor': 0,
            'itemCount': 0,
            'orderTime': m['created_at'],
            'items': <dynamic>[],
          });
        }
        debugPrint('[OrderAlert] Restored ${orders.length} pending alerts from backend.');
      }
    } catch (e) {
      debugPrint('[OrderAlert] Failed to restore pending alerts: $e');
    }
  }

  /// Staff accepts the current alert.
  Future<bool> acceptAlert(String orderId, int versionNum) async {
    final alert = _findPendingAlert(orderId);
    if (alert == null) return false;

    try {
      final actionService = _ref.read(orderActionServiceProvider);
      await actionService.queueAcceptAlert(orderId, versionNum);

      _cancelTimeoutTimer(orderId);
      final elapsed = DateTime.now().difference(alert.receivedAt);
      _updateAlertStatus(orderId, OrderAlertStatus.accepted);
      state = state.copyWith(
        totalAccepted: state.totalAccepted + 1,
        responseTimes: [...state.responseTimes, elapsed],
      );
      _removeAlertAfterDelay(orderId);
      return true;
    } catch (e) {
      debugPrint('[OrderAlert] Failed to accept order $orderId: $e');
    }
    return false;
  }

  /// Staff passes the alert to another staff member.
  Future<bool> passAlert({
    required String orderId,
    required String toStaffId,
    required String branchId,
  }) async {
    final alert = _findPendingAlert(orderId);
    if (alert == null) return false;

    try {
      final actionService = _ref.read(orderActionServiceProvider);
      await actionService.queuePassAlert(
        orderId: orderId,
        toStaffId: toStaffId,
        branchId: branchId,
      );

      _cancelTimeoutTimer(orderId);
      _updateAlertStatus(orderId, OrderAlertStatus.passed);
      state = state.copyWith(totalPassed: state.totalPassed + 1);
      _removeAlertAfterDelay(orderId);
      return true;
    } catch (e) {
      debugPrint('[OrderAlert] Failed to pass order $orderId: $e');
    }
    return false;
  }

  /// Dismiss the current alert manually (UI calls this when timeout UI expires).
  void expireAlert(String orderId) {
    _cancelTimeoutTimer(orderId);
    _updateAlertStatus(orderId, OrderAlertStatus.expired);
    state = state.copyWith(totalExpired: state.totalExpired + 1);
    _removeAlertAfterDelay(orderId);
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _startTimeoutTimer(IncomingOrderAlert alert) {
    _timeoutTimers[alert.orderId]?.cancel();
    _timeoutTimers[alert.orderId] = Timer(_alertTimeout, () {
      debugPrint('[OrderAlert] Alert timeout for order ${alert.orderId}');
      expireAlert(alert.orderId);
    });
  }

  void _cancelTimeoutTimer(String orderId) {
    _timeoutTimers[orderId]?.cancel();
    _timeoutTimers.remove(orderId);
  }

  void _updateAlertStatus(String orderId, OrderAlertStatus newStatus) {
    state = state.copyWith(
      queue: state.queue.map((a) {
        if (a.orderId == orderId) return a.copyWith(status: newStatus);
        return a;
      }).toList(),
    );
  }

  void _removeAlertAfterDelay(String orderId) {
    // Keep in queue briefly for UI to animate out, then remove
    Future.delayed(const Duration(seconds: 2), () {
      if (!_disposed) {
        state = state.copyWith(
          queue: state.queue.where((a) => a.orderId != orderId).toList(),
        );
      }
    });
  }

  IncomingOrderAlert? _findPendingAlert(String orderId) {
    try {
      return state.queue.firstWhere(
        (a) => a.orderId == orderId && a.status == OrderAlertStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final orderAlertNotifierProvider =
    StateNotifierProvider<OrderAlertNotifier, OrderAlertState>((ref) {
  return OrderAlertNotifier(ref);
});

/// Convenience: just the pending alert queue
final pendingOrderAlertsProvider = Provider<List<IncomingOrderAlert>>((ref) {
  return ref
      .watch(orderAlertNotifierProvider)
      .queue
      .where((a) => a.status == OrderAlertStatus.pending)
      .toList();
});

/// Convenience: current (top-of-queue) alert to display
final currentOrderAlertProvider = Provider<IncomingOrderAlert?>((ref) {
  return ref.watch(orderAlertNotifierProvider).currentAlert;
});

/// Convenience: current ready alert
final currentReadyAlertProvider = Provider<OrderReadyAlert?>((ref) {
  return ref.watch(orderAlertNotifierProvider).currentReadyAlert;
});
