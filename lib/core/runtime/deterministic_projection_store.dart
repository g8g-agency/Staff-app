// lib/core/runtime/deterministic_projection_store.dart

import 'package:flutter/foundation.dart';
import 'domain/runtime_event.dart';

import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/data/dtos/order_dto.dart';
import '../../features/orders/data/mappers/order_mapper.dart';
import '../../features/tables/domain/entities/restaurant_table.dart';
import '../../features/tables/data/dtos/table_dto.dart';
import '../../features/tables/data/mappers/table_mapper.dart';
import '../../features/waiter_calls/domain/entities/waiter_call.dart';

/// The authoritative local replica of backend state.
/// Realtime events strictly mutate THIS store. The UI projections then reconstruct from here.
class DeterministicProjectionStore {
  // In-memory replica simulating a local deterministic database (e.g., SQLite)
  final Map<String, Order> _orders = {};
  final Map<String, RestaurantTable> _tables = {};
  final Map<String, WaiterCall> _waiterCalls = {};
  final Map<String, dynamic> _reservations = {};
  final Map<String, dynamic> _staffPresence = {};

  // ── Authoritative Reads for Projection Rebuilders ──────────────────────────

  List<Order> getAuthoritativeOrders() => _orders.values.toList();
  List<RestaurantTable> getAuthoritativeTables() => _tables.values.toList();
  List<WaiterCall> getAuthoritativeWaiterCalls() => _waiterCalls.values.toList();
  List<dynamic> getAuthoritativeReservations() => _reservations.values.toList();
  List<dynamic> getAuthoritativePresence() => _staffPresence.values.toList();

  // ── Event Sourcing Ingestion ──────────────────────────────────────────────

  /// Called by the OperationalRuntimeBridge *after* full validation.
  Future<void> applyValidatedEvent(RuntimeEvent event) async {
    final payload = event.payload;

    switch (event.type) {
      case RuntimeEventType.orderUpdate:
        final order = _parseOrder(payload);
        _orders[order.id] = order;
        break;
      case RuntimeEventType.orderDelete:
        _orders.remove(payload['id']);
        break;

      case RuntimeEventType.tableUpdate:
        final table = _parseTable(payload);
        _tables[table.id] = table;
        break;
      case RuntimeEventType.tableDelete:
        _tables.remove(payload['id']);
        break;

      case RuntimeEventType.waiterCall:
        final call = _parseWaiterCall(payload);
        _waiterCalls[call.id] = call;
        break;
      case RuntimeEventType.waiterCallDelete:
        _waiterCalls.remove(payload['id']);
        break;

      case RuntimeEventType.reservationUpdate:
        _reservations[payload['id']] = payload;
        break;
      case RuntimeEventType.reservationDelete:
        _reservations.remove(payload['id']);
        break;
        
      case RuntimeEventType.staffPresenceUpdate:
        _staffPresence[payload['staffId']] = payload;
        break;
      case RuntimeEventType.staffPresenceDelete:
        _staffPresence.remove(payload['staffId']);
        break;

      default:
        // Ignore unhandled mapping domains
        break;
    }
    debugPrint('[DeterministicProjectionStore] Applied backend event: ${event.type}');
  }

  // ── Initial Seeding from Hydrator ─────────────────────────────────────────

  void seedOrders(List<Order> orders) {
    for (var o in orders) { _orders[o.id] = o; }
  }

  void seedTables(List<RestaurantTable> tables) {
    for (var t in tables) { _tables[t.id] = t; }
  }

  void seedWaiterCalls(List<WaiterCall> calls) {
    for (var c in calls) { _waiterCalls[c.id] = c; }
  }

  void reset() {
    _orders.clear();
    _tables.clear();
    _waiterCalls.clear();
    _reservations.clear();
    _staffPresence.clear();
    debugPrint('[DeterministicProjectionStore] Projection store reset');
  }

  // ── Parsers (Moved from RealtimeSyncManager) ──────────────────────────────

  Order _parseOrder(Map<String, dynamic> payload) {
    // Support two payload shapes:
    //  1. Flat (old createOrderFromCart broadcast): payload IS the order
    //  2. Nested (new KDS broadcast): payload['order'] is the order
    final data = (payload.containsKey('order') && payload['order'] is Map)
        ? (payload['order'] as Map<String, dynamic>)
        : payload;

    final itemList = (data['items'] as List?) ??
        (data['order_items'] as List?) ??
        (data['snapshot']?['items'] as List?) ??
        [];

    final rawItems = itemList.map((item) {
      final i = item as Map<String, dynamic>;
      final name = i['name'] ?? i['item_name_snapshot'] ?? i['menu_item_name'] ?? 'Item';
      final qty = (i['qty'] ?? i['quantity'] ?? 1) as int;
      final unitPriceMinor = i['unit_price_minor'] as num?;
      final unitPrice = unitPriceMinor != null
          ? (unitPriceMinor / 100).toDouble()
          : (i['unit_price'] as num? ?? 0.0).toDouble();
      final priceInCents = (unitPrice * 100).round();
      final menuItemId = i['menu_item_id']?.toString() ?? i['id']?.toString() ?? 'unknown';
      return {
        'id': i['id']?.toString() ?? '',
        'product': {
          'id': menuItemId,
          'name': name,
          'priceInCents': priceInCents,
          'category': 'Mains',
          'availableModifiers': [],
        },
        'quantity': qty,
        'selectedModifiers': [],
        'seatNumber': 1,
        'status': i['status']?.toString() ?? 'queued',
      };
    }).toList();

    final backendStatus = data['status']?.toString() ?? 'pending';
    String flutterStatus = 'sent';
    switch (backendStatus.toLowerCase()) {
      case 'pending':
      case 'accepted':
        flutterStatus = 'sent';
        break;
      case 'preparing':
        flutterStatus = 'preparing';
        break;
      case 'ready':
        flutterStatus = 'ready';
        break;
      case 'delivered':
        flutterStatus = 'delivered';
        break;
      case 'completed':
        flutterStatus = 'completed';
        break;
      case 'cancelled':
        flutterStatus = 'cancelled';
        break;
    }

    final staffOrderJson = {
      'id': data['id'],
      'tableId': data['table_id'] ?? payload['tableId'] ?? '',
      'items': rawItems,
      'status': flutterStatus,
      'createdAt': data['created_at'] ?? payload['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': data['updated_at'] ?? payload['updatedAt'] ?? DateTime.now().toIso8601String(),
      'waiterName': data['staff_name'] ?? data['waiterName'] ?? 'John Doe',
      'cancelLogs': [],
    };
    return OrderDto.fromJson(staffOrderJson).toDomain();
  }

  RestaurantTable _parseTable(Map<String, dynamic> payload) {
    final staffTableJson = {
      'id': payload['id'],
      'label': payload['label'],
      'capacity': payload['capacity'],
      'status': payload['status'] ?? 'available',
      'active_order_id': payload['active_order_id'],
      'occupied_seats': payload['occupied_seats'] ?? [],
      'merged_table_ids': payload['merged_table_ids'] ?? [],
    };
    return TableDto.fromMap(staffTableJson).toDomain();
  }

  WaiterCall _parseWaiterCall(Map<String, dynamic> payload) {
    return WaiterCall(
      id: payload['id'] as String,
      tableId: payload['tableId'] as String,
      tableLabel: payload['tableLabel'] as String,
      type: CallType.values.firstWhere((e) => e.name == payload['type'] as String),
      status: CallStatus.values.firstWhere((e) => e.name == payload['status'] as String),
      customerNote: payload['customerNote'] as String?,
      timestamp: DateTime.parse(payload['timestamp'] as String),
      waiterId: payload['waiterId'] as String?,
      waiterName: payload['waiterName'] as String?,
      isVip: payload['isVip'] as bool? ?? false,
    );
  }
}
