// lib/features/tables/data/datasources/local/tables_local_datasource_impl.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dtos/table_dto.dart';
import 'tables_local_datasource.dart';

class TablesLocalDatasourceImpl implements TablesLocalDatasource {
  final SharedPreferences _prefs;
  static const _key = 'cached_restaurant_tables';
  
  final _controller = StreamController<List<TableDto>>.broadcast();

  TablesLocalDatasourceImpl(this._prefs) {
    // Seed initial broadcast from cache
    final initial = _readFromPrefs();
    _controller.add(initial);
  }

  List<TableDto> _readFromPrefs() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => TableDto.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<TableDto>> getCachedTables() async {
    return _readFromPrefs();
  }

  @override
  Future<void> cacheTables(List<TableDto> tables) async {
    final raw = jsonEncode(tables.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, raw);
    _controller.add(tables);
  }

  @override
  Future<void> cacheTable(TableDto table) async {
    final current = _readFromPrefs();
    final index = current.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      current[index] = table;
    } else {
      current.add(table);
    }
    await cacheTables(current);
  }

  @override
  Stream<List<TableDto>> watchCachedTables() {
    return _controller.stream;
  }
}
