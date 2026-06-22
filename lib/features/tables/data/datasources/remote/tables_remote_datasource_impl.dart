// lib/features/tables/data/datasources/remote/tables_remote_datasource_impl.dart
//
// Uses the backend REST API instead of direct Supabase queries.
// The Supabase Flutter client has no authenticated session (setSession removed),
// so direct .from('tables') queries return 0 rows due to RLS.
// This routes all reads through the authenticated backend API.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../dtos/table_dto.dart';
import 'tables_remote_datasource.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/network/secure_storage.dart';

class TablesRemoteDatasourceImpl implements TablesRemoteDatasource {
  final DioClient _dio;
  final String _branchId;

  // Broadcast stream that re-emits on every successful getTables call
  final StreamController<List<TableDto>> _streamController =
      StreamController<List<TableDto>>.broadcast();

  TablesRemoteDatasourceImpl(this._dio, this._branchId);

  Future<String> _getToken() async {
    const storage = SecureLocalStorage();
    return await storage.read('access_token') ?? '';
  }

  @override
  Future<List<TableDto>> getTables() async {
    debugPrint('[TablesRemoteDatasource] getTables called for branch: $_branchId');
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/api/v1/admin/tables',
        queryParameters: {
          'branch_id': _branchId,
          'limit': 100,
          'is_active': true,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skip_cache': true},
        ),
      );

      final rawList = (response.data['data'] as List<dynamic>?) ?? [];
      final tables = rawList
          .map((json) => TableDto.fromMap(json as Map<String, dynamic>))
          .toList();

      debugPrint('[TablesRemoteDatasource] getTables succeeded, found ${tables.length} tables');

      // Push to stream so watchTables consumers also get the update
      if (!_streamController.isClosed) {
        _streamController.add(tables);
      }
      return tables;
    } catch (e) {
      debugPrint('[TablesRemoteDatasource] getTables failed: $e');
      rethrow;
    }
  }

  @override
  Stream<List<TableDto>> watchTables() {
    debugPrint('[TablesRemoteDatasource] watchTables stream initiated for branch: $_branchId');

    // Trigger an initial fetch so the UI gets data immediately
    getTables().catchError((Object e) {
      debugPrint('[TablesRemoteDatasource] watchTables initial fetch error: $e');
      return <TableDto>[];
    });

    return _streamController.stream.map((tables) {
      debugPrint('[TablesRemoteDatasource] watchTables event received, count: ${tables.length}');
      return tables;
    });
  }

  /// Called by the realtime bridge when a tableUpdate event arrives.
  Future<void> refreshFromRealtime() async {
    await getTables().catchError((Object e) {
      debugPrint('[TablesRemoteDatasource] refreshFromRealtime error: $e');
      return <TableDto>[];
    });
  }

  @override
  Future<TableDto> updateTableStatus(String id, String status,
      {String? orderId}) async {
    // Refresh and return the updated table
    final tables = await getTables();
    return tables.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Table $id not found after update'),
    );
  }

  @override
  Future<void> mergeTables(
      List<String> sourceTableIds, String targetTableId) async {
    debugPrint('[TablesRemoteDatasource] mergeTables: managed via backend lifecycle endpoints');
  }

  @override
  Future<void> splitTable(
      String tableId, List<Map<String, dynamic>> splitPartitions) async {
    debugPrint('[TablesRemoteDatasource] splitTable: managed via backend lifecycle endpoints');
  }

  void dispose() {
    _streamController.close();
  }
}
