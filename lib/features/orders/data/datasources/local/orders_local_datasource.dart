// lib/features/orders/data/datasources/local/orders_local_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dtos/order_dto.dart';

abstract class OrdersLocalDatasource {
  Future<List<OrderDto>> getCachedOrders();
  Future<OrderDto?> getCachedOrderById(String id);
  Future<OrderDto?> getActiveOrderForTable(String tableId);
  Future<void> cacheOrders(List<OrderDto> orders);
  Future<void> cacheOrder(OrderDto order);
  Stream<List<OrderDto>> watchCachedOrders();
}

class OrdersLocalDatasourceImpl implements OrdersLocalDatasource {
  final SharedPreferences _prefs;
  static const _key = 'cached_restaurant_orders';
  
  final _controller = StreamController<List<OrderDto>>.broadcast();

  OrdersLocalDatasourceImpl(this._prefs) {
    _controller.add(_readFromPrefs());
  }

  List<OrderDto> _readFromPrefs() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => OrderDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<OrderDto>> getCachedOrders() async {
    return _readFromPrefs();
  }

  @override
  Future<OrderDto?> getCachedOrderById(String id) async {
    final current = _readFromPrefs();
    final index = current.indexWhere((o) => o.id == id);
    return index != -1 ? current[index] : null;
  }

  @override
  Future<OrderDto?> getActiveOrderForTable(String tableId) async {
    final current = _readFromPrefs();
    
    // 1. Prefer draft status order
    var index = current.indexWhere((o) => o.tableId == tableId && o.status == 'draft');
    if (index != -1) return current[index];
    
    // 2. Otherwise prefer the most recent active order
    final activeOrders = current.where((o) => o.tableId == tableId && o.status != 'completed' && o.status != 'cancelled').toList();
    if (activeOrders.isEmpty) return null;
    
    activeOrders.sort((a, b) {
      final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime); // descending (most recent first)
    });
    
    return activeOrders.first;
  }

  @override
  Future<void> cacheOrders(List<OrderDto> orders) async {
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs.setString(_key, raw);
    _controller.add(orders);
  }

  @override
  Future<void> cacheOrder(OrderDto order) async {
    final current = _readFromPrefs();
    final index = current.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      current[index] = order;
    } else {
      current.add(order);
    }
    await cacheOrders(current);
  }

  @override
  Stream<List<OrderDto>> watchCachedOrders() async* {
    yield _readFromPrefs();
    yield* _controller.stream;
  }
}
