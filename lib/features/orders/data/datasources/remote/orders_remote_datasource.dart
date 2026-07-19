// lib/features/orders/data/datasources/remote/orders_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  Future<Options> _getAuthOptions() async {
    const secureStorage = SecureLocalStorage();
    final token = await secureStorage.read('runtime_token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
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
        options: options,
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
        options: options,
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
  Map<String, dynamic> _mapBackendOrder(Map<String, dynamic> payload) {
    if (payload.containsKey('tableId') && payload.containsKey('createdAt')) {
      return payload; // Already mapped (e.g. from mock)
    }

    final items = (payload['items'] as List? ?? []).map((item) {
      final i = item as Map<String, dynamic>;
      final rawPrice = double.tryParse(i['unit_price']?.toString() ?? '') ?? 0.0;
      final priceInCents = (rawPrice * 100).round();
      return {
        'id': i['id'],
        'product': {
          'id': i['menu_item_id'] ?? i['productId'] ?? 'unknown',
          'name': i['name'] ?? i['menu_item_name'] ?? 'Product',
          'priceInCents': priceInCents,
          'category': 'Mains',
          'availableModifiers': [],
        },
        'quantity': i['quantity'] ?? i['qty'] ?? 1,
        'selectedModifiers': [],
        'seatNumber': 1,
        'status': i['status'] ?? 'confirmed',
      };
    }).toList();

    // Translate backend status names to Flutter OrderStatus enum names
    final backendStatus = payload['status']?.toString() ?? 'pending';
    final flutterStatus = _translateBackendStatus(backendStatus);

    return {
      'id': payload['id'],
      'tableId': payload['table_id'] ?? '',
      'items': items,
      'status': flutterStatus,
      'createdAt': payload['created_at'] ?? DateTime.now().toIso8601String(),
      'updatedAt': payload['updated_at'] ?? DateTime.now().toIso8601String(),
      'waiterName': payload['staff_name'] ?? payload['waiterName'] ?? 'John Doe',
      'cancelLogs': [],
    };
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
