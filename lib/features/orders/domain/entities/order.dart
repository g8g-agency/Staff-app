// lib/features/orders/domain/entities/order.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';
import 'order_item.dart';

enum OrderStatus {
  draft,
  sent,
  preparing,
  ready,
  delivered,
  completed,
  cancelled,
}

class Order extends Equatable {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String waiterName;
  final List<String> cancelLogs;
  final String? customerPaymentIntent;

  const Order({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.waiterName = 'John Doe',
    this.cancelLogs = const [],
    this.customerPaymentIntent,
  });

  bool get isPaymentRequested =>
      customerPaymentIntent != null &&
      status != OrderStatus.completed &&
      status != OrderStatus.cancelled;

  Money get totalPrice {
    var total = const Money(amountInCents: 0);
    for (final item in items) {
      if (item.status != OrderItemStatus.cancelled) {
        total = total + item.totalPrice;
      }
    }
    return total;
  }

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? waiterName,
    List<String>? cancelLogs,
    String? customerPaymentIntent,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      waiterName: waiterName ?? this.waiterName,
      cancelLogs: cancelLogs ?? this.cancelLogs,
      customerPaymentIntent: customerPaymentIntent ?? this.customerPaymentIntent,
    );
  }

  @override
  List<Object?> get props => [id, tableId, items, status, createdAt, updatedAt, waiterName, cancelLogs, customerPaymentIntent];
}
