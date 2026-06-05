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

    final receivedAt = DateTime.now();
    return IncomingOrderAlert(
      alertId: '${payload['orderId']}_${receivedAt.millisecondsSinceEpoch}',
      orderId: (payload['orderId'] as String?) ?? '',
      orderNumber: (payload['orderNumber'] as String?) ?? 'N/A',
      tableNumber: (payload['tableNumber'] as String?) ?? 'N/A',
      assignedStaffId: payload['assignedStaffId'] as String?,
      itemCount: (payload['itemCount'] as int?) ?? itemsList.length,
      totalAmountMinor: (payload['totalAmountMinor'] as int?) ?? 0,
      versionNum: (payload['versionNum'] as int?) ?? 1,
      orderTime: DateTime.tryParse((payload['orderTime'] as String?) ?? '') ?? receivedAt,
      receivedAt: receivedAt,
      items: itemsList,
      status: OrderAlertStatus.pending,
      isReassignment: (payload['isReassignment'] as bool?) ?? false,
    );
  }

  IncomingOrderAlert copyWith({OrderAlertStatus? status}) {
    return IncomingOrderAlert(
      alertId: alertId,
      orderId: orderId,
      orderNumber: orderNumber,
      tableNumber: tableNumber,
      assignedStaffId: assignedStaffId,
      itemCount: itemCount,
      totalAmountMinor: totalAmountMinor,
      versionNum: versionNum,
      orderTime: orderTime,
      receivedAt: receivedAt,
      items: items,
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
      alertId: '${payload['orderId']}_ready_${DateTime.now().millisecondsSinceEpoch}',
      orderId: (payload['orderId'] as String?) ?? '',
      orderNumber: (payload['orderNumber'] as String?) ?? 'N/A',
      tableNumber: (payload['tableNumber'] as String?) ?? 'N/A',
      assignedStaffId: payload['assignedStaffId'] as String?,
      assignedStaffName: payload['assignedStaffName'] as String?,
      readyAt: DateTime.tryParse((payload['readyAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [alertId, orderId];
}
