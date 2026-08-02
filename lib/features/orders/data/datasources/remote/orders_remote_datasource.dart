// lib/features/orders/data/datasources/remote/orders_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/network/dio_client.dart';
import '../../../../../../core/network/secure_storage.dart';
import '../../dtos/order_dto.dart';

abstract class OrdersRemoteDatasource {
  Future<List<OrderDto>> fetchActiveOrders(String branchId);
  Future<OrderDto?> getOrderById(String orderId);
  Future<OrderDto> checkoutCart(Map<String, dynamic> envelope);
  Future<OrderDto> transitionStatus(String orderId, Map<String, dynamic> envelope);
}

class OrdersRemoteDatasourceImpl implements OrdersRemoteDatasource {
  final DioClient _dioClient;

  OrdersRemoteDatasourceImpl(this._dioClient);

  Future<Options?> _getAuthOptions() async {
    try {
      const secureStorage = SecureLocalStorage();
      final token = await secureStorage.read('runtime_token');
      final sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
      final authToken = (token != null && token.isNotEmpty) ? token : sessionToken;
      if (authToken != null && authToken.isNotEmpty) {
        return Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<OrderDto>> fetchActiveOrders(String branchId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dioClient.get(
        '/api/v1/orders',
        queryParameters: {
          'branchId': branchId,
        },
        options: options?.copyWith(extra: {'skip_cache': true}) ?? Options(extra: {'skip_cache': true}),
      );

      if (response.statusCode == 200) {
        final list = response.data['data']['orders'] as List;
        return list.map((json) {
          final mapped = _mapBackendOrder(json as Map<String, dynamic>);
          return OrderDto.fromJson(mapped);
        }).toList();
      }
    } catch (e) {
      debugPrint('[OrdersRemoteDatasource] Failed to fetch active orders: $e');
      rethrow;
    }
    throw Exception('Failed to fetch active orders');
  }

  @override
  Future<OrderDto?> getOrderById(String orderId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dioClient.get(
        '/api/v1/orders/$orderId',
        options: options?.copyWith(extra: {'skip_cache': true}) ?? Options(extra: {'skip_cache': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['order'];
        if (data != null) {
          final mapped = _mapBackendOrder(data as Map<String, dynamic>);
          return OrderDto.fromJson(mapped);
        }
      }
    } catch (e) {
      debugPrint('[OrdersRemoteDatasource] Failed to get order by ID: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<OrderDto> checkoutCart(Map<String, dynamic> envelope) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dioClient.post(
        '/api/v1/orders/checkout',
        data: envelope,
        options: options,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data']['order'];
        final mapped = _mapBackendOrder(data as Map<String, dynamic>);
        return OrderDto.fromJson(mapped);
      }
    } catch (e) {
      debugPrint('[OrdersRemoteDatasource] Failed to checkout cart: $e');
      rethrow;
    }
    throw Exception('Failed to checkout cart');
  }

  @override
  Future<OrderDto> transitionStatus(String orderId, Map<String, dynamic> envelope) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dioClient.patch(
        '/api/v1/orders/$orderId/status',
        data: envelope,
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['order'] as Map<String, dynamic>;
        final mapped = _mapBackendOrder(data);
        return OrderDto.fromJson(mapped);
      }
    } catch (e) {
      debugPrint('[OrdersRemoteDatasource] Failed to transition order status: $e');
      rethrow;
    }
    throw Exception('Failed to transition order status');
  }
  /// Maps a backend order payload (from GET /api/v1/orders or /api/v1/orders/:id) to
  /// the shape expected by OrderDto.fromJson.
  ///
  /// Backend item shape (from order_item_snapshots via snapshot join):
  ///   { name: item_name_snapshot, qty: quantity, unit_price: unit_price_minor/100,
  ///     line_total: line_total_minor/100 }
  ///
  /// NOTE: unit_price is already in RUPEES (backend divides unit_price_minor / 100).
  ///       Do NOT multiply by 100 again — convert directly to paise by *100.
  Map<String, dynamic> _mapBackendOrder(Map<String, dynamic> payload) {
    final orderId = payload['id']?.toString() ?? '';

    final rawItemList = (payload['items'] as List?) ??
        (payload['order_items'] as List?) ??
        (payload['snapshot']?['items'] as List?) ??
        [];

    final items = List.generate(rawItemList.length, (index) {
      final i = rawItemList[index] as Map<String, dynamic>;

      // Backend sends unit_price already in RUPEES (it divided unit_price_minor by 100).
      // We must NOT treat it as minor units. Convert rupees → paise by * 100.
      final rawPrice = i['unit_price'];
      final priceInRupees = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString().replaceAll('null', '') ?? '') ?? 0.0;
      final priceInCents = (priceInRupees * 100).round();

      // Name: backend maps item_name_snapshot → 'name'
      final name = _safeStr(i['name']) ??
          _safeStr(i['item_name_snapshot']) ??
          _safeStr(i['menu_item_name']) ??
          'Item';

      // Quantity: backend maps quantity → 'qty'
      final quantity = ((i['qty'] ?? i['quantity'] ?? 1) as num).toInt();

      // Seat number: preserve from payload if present; default 1 for backward compat
      final seatNumber = ((i['seat_number'] ?? i['seatNumber'] ?? 1) as num).toInt();

      // Item ID: order_item_snapshots has no id column — backend returns '' always.
      // Generate a stable deterministic ID from orderId + index to prevent duplicate keys.
      final itemId = _safeStr(i['id'])?.isNotEmpty == true
          ? i['id'].toString()
          : '${orderId}_item_$index';

      return {
        'id': itemId,
        'product': {
          'id': _safeStr(i['menu_item_id']) ??
              _safeStr(i['productId']) ??
              '${orderId}_product_$index',
          'name': name,
          'priceInCents': priceInCents,
          // Do NOT set stale category from menu — use empty string.
          // The OrderDetails screen does not display category for items from history.
          'category': '',
          'availableModifiers': [],
        },
        'quantity': quantity,
        'selectedModifiers': [],
        'seatNumber': seatNumber,
        'status': _safeStr(i['status']) ?? 'queued',
      };
    });

    // Translate backend status names to Flutter OrderStatus enum names
    final backendStatus = _safeStr(payload['status']) ?? 'pending';
    final flutterStatus = _translateBackendStatus(backendStatus);

    return {
      'id': orderId,
      'tableId': _safeStr(payload['table_id']) ?? _safeStr(payload['tableId']) ?? '',
      'items': items,
      'status': flutterStatus,
      'createdAt': _safeStr(payload['created_at']) ?? _safeStr(payload['createdAt']) ?? DateTime.now().toIso8601String(),
      'updatedAt': _safeStr(payload['updated_at']) ?? _safeStr(payload['updatedAt']) ?? DateTime.now().toIso8601String(),
      // Do NOT default to 'John Doe' — use empty string so UI shows 'Unassigned' correctly.
      'waiterName': _safeStr(payload['staff_name']) ?? _safeStr(payload['waiterName']) ?? '',
      'cancelLogs': [],
      'version_num': payload['version_num'] ?? 1,
      'customer_payment_intent': payload['customer_payment_intent'],
    };
  }

  /// Returns null for null/empty/literal-'null' strings, otherwise the string value.
  String? _safeStr(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  /// Translates backend order status strings to Flutter OrderStatus enum names.
  /// Backend: pending, accepted, preparing, ready, delivered, completed, cancelled
  /// Flutter enum: draft, sent, preparing, ready, delivered, completed, cancelled
  String _translateBackendStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'sent';       // pending on server = sent to kitchen from staff app
      case 'accepted':
        return 'sent';       // accepted by kitchen = still in-progress for staff
      case 'preparing':
        return 'preparing';
      case 'ready':
        return 'ready';
      case 'delivered':
        return 'delivered';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'sent';       // unknown → treat as active
    }
  }
}
