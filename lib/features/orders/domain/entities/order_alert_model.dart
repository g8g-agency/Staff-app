// lib/features/orders/domain/entities/order_alert_model.dart
import 'package:equatable/equatable.dart';

enum OrderAlertStatus {
  pending,   // Waiting for staff response
  accepted,  // Staff accepted
  passed,    // Staff passed to another
  expired,   // 30s timeout — not responded
  missed,    // Similar to expired, for offline staff
}

class AlertOrderItem extends Equatable {
  final String name;
  final int quantity;

  const AlertOrderItem({required this.name, required this.quantity});

  factory AlertOrderItem.fromMap(Map<String, dynamic> map) {
    return AlertOrderItem(
      name: (map['name'] as String?) ?? 'Unknown Item',
      quantity: (map['quantity'] as int?) ?? 1,
    );
  }

  @override
  List<Object?> get props => [name, quantity];
}

class IncomingOrderAlert extends Equatable {
  final String alertId;          // Unique per alert (orderId + receivedAt)
  final String orderId;
  final String orderNumber;
  final String tableNumber;
  final String? assignedStaffId;
  final int itemCount;
  final int totalAmountMinor;    // In paise/cents
  final int versionNum;           // OCC version for accept action
  final DateTime orderTime;
  final DateTime receivedAt;
  final List<AlertOrderItem> items;
  final OrderAlertStatus status;
  final bool isReassignment;

  const IncomingOrderAlert({
    required this.alertId,
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    this.assignedStaffId,
    required this.itemCount,
    required this.totalAmountMinor,
    required this.versionNum,
    required this.orderTime,
    required this.receivedAt,
    required this.items,
    this.status = OrderAlertStatus.pending,
    this.isReassignment = false,
  });

  factory IncomingOrderAlert.fromPayload(Map<String, dynamic> payload) {
    final itemsList = (payload['items'] as List<dynamic>? ?? [])
        .map((i) => AlertOrderItem.fromMap(i as Map<String, dynamic>))
        .toList();

    // Safe int extractor — JSON over WebSocket may deliver integers as num/double
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v);
      return null;
    }

    // Resolve total in minor units (paise). Backend sends totalAmountMinor as int.
    final resolvedTotalMinor =
        _toInt(payload['totalAmountMinor'] ?? payload['total_amount_minor']) ??
        (() {
          final rawPrice = payload['total_price'];
          return rawPrice is num ? (rawPrice * 100).round() : 0;
        })();

    final receivedAt = DateTime.now();
    return IncomingOrderAlert(
      alertId: '${payload['orderId'] ?? payload['id']}_${receivedAt.millisecondsSinceEpoch}',
      orderId: (payload['orderId'] ?? payload['id'])?.toString() ?? '',
      orderNumber: (payload['orderNumber'] ?? payload['order_number'])?.toString() ?? 'N/A',
      tableNumber: (payload['tableLabel'] ?? payload['tableNumber'] ?? payload['table_num'])?.toString() ?? 'N/A',
      assignedStaffId: (payload['assignedStaffId'] ?? payload['assigned_waiter_id'] ?? payload['assigned_staff_id'])?.toString(),
      itemCount: _toInt(payload['itemCount']) ?? itemsList.length,
      totalAmountMinor: resolvedTotalMinor,
      versionNum: _toInt(payload['versionNum'] ?? payload['version_num']) ?? 1,
      orderTime: DateTime.tryParse((payload['orderTime'] ?? payload['created_at'] ?? '') as String) ?? receivedAt,
      receivedAt: receivedAt,
      items: itemsList,
      status: OrderAlertStatus.pending,
      isReassignment: (payload['isReassignment'] as bool?) ?? false,
    );
  }

  IncomingOrderAlert copyWith({
    OrderAlertStatus? status,
    String? tableNumber,
    int? itemCount,
    int? totalAmountMinor,
    List<AlertOrderItem>? items,
  }) {
    return IncomingOrderAlert(
      alertId: alertId,
      orderId: orderId,
      orderNumber: orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      assignedStaffId: assignedStaffId,
      itemCount: itemCount ?? this.itemCount,
      totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
      versionNum: versionNum,
      orderTime: orderTime,
      receivedAt: receivedAt,
      items: items ?? this.items,
      status: status ?? this.status,
      isReassignment: isReassignment,
    );
  }

  /// Total amount formatted as rupees (e.g. "₹850")
  String get formattedTotal {
    final rupees = totalAmountMinor ~/ 100;
    final paise = totalAmountMinor % 100;
    if (paise == 0) return '₹$rupees';
    return '₹$rupees.${paise.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [alertId, orderId, status, versionNum];
}

class OrderReadyAlert extends Equatable {
  final String alertId;
  final String orderId;
  final String orderNumber;
  final String tableNumber;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime readyAt;

  const OrderReadyAlert({
    required this.alertId,
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.readyAt,
  });

  factory OrderReadyAlert.fromPayload(Map<String, dynamic> payload) {
    return OrderReadyAlert(
      alertId: '${payload['orderId'] ?? payload['id']}_ready_${DateTime.now().millisecondsSinceEpoch}',
      orderId: (payload['orderId'] ?? payload['id'])?.toString() ?? '',
      orderNumber: (payload['orderNumber'] ?? payload['order_number'])?.toString() ?? 'N/A',
      tableNumber: (payload['tableNumber'] ?? payload['table_num'] ?? payload['table_id'])?.toString() ?? 'N/A',
      assignedStaffId: (payload['assignedStaffId'] ?? payload['assigned_waiter_id'])?.toString(),
      assignedStaffName: payload['assignedStaffName']?.toString(),
      readyAt: DateTime.tryParse((payload['readyAt'] ?? payload['ready_at'] ?? '') as String) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [alertId, orderId];
}
