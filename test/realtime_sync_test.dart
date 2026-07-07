import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orderlyy_app/bootstrap/bootstrap.dart';
import 'package:orderlyy_app/core/network/realtime_sync_manager.dart';
import 'package:orderlyy_app/features/orders/providers/orders_providers.dart';
import 'package:orderlyy_app/features/tables/providers/tables_providers.dart';
import 'package:orderlyy_app/features/waiter_calls/presentation/state/waiter_calls_providers.dart';
import 'package:orderlyy_app/features/waiter_calls/domain/entities/waiter_call.dart';
import 'package:orderlyy_app/core/network/network_info.dart';
import 'package:orderlyy_app/core/network/network_providers.dart';
import 'package:orderlyy_app/core/network/offline_queue.dart';
import 'package:orderlyy_app/features/tables/data/datasources/remote/tables_remote_datasource.dart';
import 'package:orderlyy_app/features/tables/data/dtos/table_dto.dart';
import 'package:orderlyy_app/core/config/app_config.dart';
import 'package:orderlyy_app/core/config/environment.dart';
import 'package:orderlyy_app/core/runtime/operational_runtime_bridge.dart';

import 'package:hive/hive.dart';
import 'package:orderlyy_app/core/runtime/realtime_transport_provider.dart';
import 'package:orderlyy_app/core/device/device_fingerprint_provider.dart';

// Mock classes for testing
class MockHiveBox implements Box<String> {
  final Map<String, String> _storage = {};

  @override
  String? get(key, {String? defaultValue}) => _storage[key.toString()] ?? defaultValue;

  @override
  Future<void> put(key, String value) async {
    _storage[key.toString()] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTablesRemoteDatasource implements TablesRemoteDatasource {
  List<TableDto> tables = [];
  bool getTablesCalled = false;
  String? updatedId;
  String? updatedStatus;
  String? updatedOrderId;

  @override
  Future<List<TableDto>> getTables() async {
    getTablesCalled = true;
    return tables;
  }

  @override
  Future<TableDto> updateTableStatus(String id, String status, {String? orderId}) async {
    updatedId = id;
    updatedStatus = status;
    updatedOrderId = orderId;
    return TableDto(id: id, label: 'Table $id', capacity: 4, status: status, activeOrderId: orderId);
  }

  @override
  Stream<List<TableDto>> watchTables() {
    return Stream.value(tables);
  }

  @override
  Future<void> mergeTables(List<String> sourceTableIds, String targetTableId) async {}

  @override
  Future<void> splitTable(String tableId, List<Map<String, dynamic>> splitPartitions) async {}
}

class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Stream<bool> get onConnectionChanged => Stream.value(isConnectedValue);
}

class MockOfflineQueueManager implements OfflineQueueManager {
  List<Map<String, dynamic>> queued = [];

  @override
  Future<void> queueWrite({required String action, required Map<String, dynamic> payload}) async {
    queued.add({'action': action, 'payload': payload});
  }

  @override
  void registerHandler(String action, OfflineWriteHandler handler) {}

  @override
  Future<void> processQueue() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeSyncManager Integration Tests', () {
    late ProviderContainer container;
    late MockTablesRemoteDatasource mockRemote;
    late MockNetworkInfo mockNetwork;
    late MockOfflineQueueManager mockOfflineQueue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      AppConfig.initialize(
        environment: Environment.dev,
        apiBaseUrl: 'http://localhost:8000',
        websocketUrl: 'ws://localhost:8000',
        enableSentry: false,
      );
      
      mockRemote = MockTablesRemoteDatasource();
      mockNetwork = MockNetworkInfo();
      mockOfflineQueue = MockOfflineQueueManager();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tablesRemoteDatasourceProvider.overrideWithValue(mockRemote),
          networkInfoProvider.overrideWithValue(mockNetwork),
          offlineQueueManagerProvider.overrideWithValue(mockOfflineQueue),
          repositoryModeProvider.overrideWithValue(RepositoryMode.mock),
          apiCacheBoxProvider.overrideWithValue(MockHiveBox()),
          deviceFingerprintProvider.overrideWithValue('mock_device_fingerprint'),
        ],
      );

      // Initialize the bridge to listen to sync events
      container.read(operationalRuntimeBridgeProvider);

      // Start orchestrator session with defaults matching bridge expectations
      container.read(runtimeOrchestratorProvider).startSession(
        branchId: 'branch_default',
        staffId: 'test_staff_123',
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should parse and apply order_update sync event', () async {
      final syncManager = container.read(realtimeSyncManagerProvider);
      final ordersRepo = container.read(ordersRepositoryProvider);

      final orderPayload = {
        'id': 'test_ord_123',
        'table_id': 'test_tbl_123',
        'status': 'preparing',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'total_amount': 25.50,
        'items': [
          {
            'id': 'item_1',
            'menu_item_id': 'prod_burger',
            'menu_item_name': 'Classic Cheeseburger',
            'quantity': 2,
            'unit_price': 12.50,
          }
        ]
      };

      syncManager.receiveRawPayload({
        'idempotencyKey': 'idem-test-order-123',
        'sequenceNumber': 1,
        'type': 'order_update',
        'payload': orderPayload,
      });

      // Let the stream listener process the event
      await Future.delayed(const Duration(milliseconds: 100));

      final order = await ordersRepo.getOrderById('test_ord_123');
      expect(order, isNotNull);
      expect(order!.id, 'test_ord_123');
      expect(order.tableId, 'test_tbl_123');
      expect(order.status.name, 'preparing');
      expect(order.items.length, 1);
      expect(order.items[0].product.id, 'prod_burger');
      expect(order.items[0].quantity, 2);
    });

    test('should parse and apply table_update sync event', () async {
      mockNetwork.isConnectedValue = false;
      final syncManager = container.read(realtimeSyncManagerProvider);
      final tablesRepo = container.read(tablesRepositoryProvider);

      final tablePayload = {
        'id': 'test_tbl_123',
        'label': 'Table 123',
        'capacity': 4,
        'status': 'occupied',
        'active_order_id': 'test_ord_123',
      };

      syncManager.receiveRawPayload({
        'idempotencyKey': 'idem-test-table-123',
        'sequenceNumber': 1,
        'type': 'table_update',
        'payload': tablePayload,
      });

      // Let the stream listener process the event
      await Future.delayed(const Duration(milliseconds: 100));

      final tables = await tablesRepo.getTables();
      final table = tables.firstWhere((t) => t.id == 'test_tbl_123');
      expect(table, isNotNull);
      expect(table.label, 'Table 123');
      expect(table.status.name, 'occupied');
      expect(table.activeOrderId, 'test_ord_123');
    });

    test('should parse and apply waiter_call sync event', () async {
      final syncManager = container.read(realtimeSyncManagerProvider);
      final waiterCallsRepo = container.read(waiterCallsRepositoryProvider);

      final callPayload = {
        'id': 'test_call_123',
        'tableId': 'test_tbl_123',
        'tableLabel': 'Table 123',
        'type': 'billRequest',
        'status': 'pending',
        'customerNote': 'Bill please',
        'timestamp': DateTime.now().toIso8601String(),
        'isVip': true,
      };

      syncManager.receiveRawPayload({
        'idempotencyKey': 'idem-test-call-123',
        'sequenceNumber': 1,
        'type': 'waiter_call',
        'payload': callPayload,
      });

      // Let the stream listener process the event
      await Future.delayed(const Duration(milliseconds: 100));

      final calls = await waiterCallsRepo.getCachedWaiterCalls();
      final call = calls.firstWhere((c) => c.id == 'test_call_123');
      expect(call, isNotNull);
      expect(call.tableLabel, 'Table 123');
      expect(call.type, CallType.billRequest);
      expect(call.status, CallStatus.pending);
      expect(call.isVip, isTrue);
    });
  });
}
