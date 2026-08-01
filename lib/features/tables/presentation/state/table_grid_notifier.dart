// lib/features/tables/presentation/state/table_grid_notifier.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../providers/tables_providers.dart';
import 'table_grid_state.dart';

part 'table_grid_notifier.g.dart';

@riverpod
class TableGridNotifier extends _$TableGridNotifier {
  StreamSubscription<List<RestaurantTable>>? _subscription;

  @override
  FutureOr<TableGridState> build() async {
    final useCase = ref.watch(watchTablesUseCaseProvider);
    
    // Clean up previous subscriptions if any
    ref.onDispose(() {
      _subscription?.cancel();
    });

    final completer = Completer<TableGridState>();
    
    // Subscribe to domain stream of table changes
    _subscription = useCase().listen(
      (tables) {
        state = AsyncData(TableGridState(tables: tables, isLoading: false));
        if (!completer.isCompleted) {
          completer.complete(TableGridState(tables: tables, isLoading: false));
        }
      },
      onError: (err, stack) {
        state = AsyncError(err, stack);
        if (!completer.isCompleted) {
          completer.completeError(err, stack);
        }
      }
    );
    
    // Start with cached/db values if available
    try {
      final initialTables = await ref.read(tablesRepositoryProvider).getTables();
      if (!completer.isCompleted) {
        return TableGridState(tables: initialTables, isLoading: false);
      }
    } catch (_) {
      // Ignore initial load error, stream will update
    }

    return const TableGridState(isLoading: true);
  }

  Future<void> refreshTables() async {
    try {
      final freshTables = await ref.read(tablesRepositoryProvider).getTables();
      state = AsyncData(TableGridState(tables: freshTables, isLoading: false));
    } catch (e) {
      debugPrint('[TableGridNotifier] refreshTables failed: $e');
    }
  }

  Future<void> updateStatus(String tableId, TableStatus status) async {
    final updateUseCase = ref.read(updateTableStatusUseCaseProvider);
    final previousState = state.value;
    
    state = AsyncData(TableGridState(
      tables: previousState?.tables ?? [],
      isLoading: true,
    ));

    try {
      await updateUseCase(tableId, status);
    } catch (e) {
      state = AsyncData(TableGridState(
        tables: previousState?.tables ?? [],
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> mergeTables(List<String> sourceTableIds, String targetTableId) async {
    final previousState = state.value;
    state = AsyncData(TableGridState(
      tables: previousState?.tables ?? [],
      isLoading: true,
    ));

    try {
      await ref.read(tablesRepositoryProvider).mergeTables(sourceTableIds, targetTableId);
    } catch (e) {
      state = AsyncData(TableGridState(
        tables: previousState?.tables ?? [],
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> splitTable(String tableId, List<Map<String, dynamic>> splitPartitions) async {
    final previousState = state.value;
    state = AsyncData(TableGridState(
      tables: previousState?.tables ?? [],
      isLoading: true,
    ));

    try {
      await ref.read(tablesRepositoryProvider).splitTable(tableId, splitPartitions);
    } catch (e) {
      state = AsyncData(TableGridState(
        tables: previousState?.tables ?? [],
        errorMessage: e.toString(),
      ));
    }
  }
}
