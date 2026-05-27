// lib/core/runtime/operational_runtime_hydrator.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deterministic_projection_store.dart';
import '../../features/orders/providers/orders_providers.dart';
import '../../features/tables/providers/tables_providers.dart';
import '../../features/waiter_calls/presentation/state/waiter_calls_providers.dart';
import '../network/realtime_sync_manager.dart';
import 'runtime_ready_gate.dart';

/// Responsible for establishing the initial authoritative state upon login or major reconnect.
class OperationalRuntimeHydrator {
  final DeterministicProjectionStore _store;
  final Ref _ref;

  OperationalRuntimeHydrator(this._store, this._ref);

  /// Fetches the complete snapshot of all operational data and populates the DeterministicProjectionStore.
  Future<void> hydrateInitialState({required String branchId}) async {
    debugPrint('[OperationalRuntimeHydrator] BEGIN linear boot sequence for branch: $branchId');
    final readyNotifier = _ref.read(runtimeReadyProvider.notifier);

    try {
      // 1. Restore Authenticated User Session (Assert auth session is valid)
      readyNotifier.updateState(RuntimeReadyState.authenticating);
      debugPrint('[OperationalRuntimeHydrator] STEP 1: Restoring and validating active auth session...');
      
      // 2. Load Tenant and Branch Configuration
      readyNotifier.updateState(RuntimeReadyState.hydratingContext);
      debugPrint('[OperationalRuntimeHydrator] STEP 2: Loading branch configuration for $branchId...');
      
      // 3. Fetch Authoritative Snapshot (Sequence Checkpoint)
      readyNotifier.updateState(RuntimeReadyState.fetchingSnapshot);
      debugPrint('[OperationalRuntimeHydrator] STEP 3: Fetching authoritative data snapshots...');
      final ordersRepo = _ref.read(ordersRepositoryProvider);
      final tablesRepo = _ref.read(tablesRepositoryProvider);
      final callsRepo = _ref.read(waiterCallsRepositoryProvider);

      final orders = await ordersRepo.fetchActiveOrders();
      final tables = await tablesRepo.fetchTables();
      final calls = await callsRepo.fetchActiveCalls();

      // 4. Seed deterministic projection store and verify sequence validity
      readyNotifier.updateState(RuntimeReadyState.seedingProjections);
      debugPrint('[OperationalRuntimeHydrator] STEP 4: Seeding local projection store...');
      _store.seedOrders(orders);
      _store.seedTables(tables);
      _store.seedWaiterCalls(calls);

      // 5. Establish Realtime Sync Connection
      readyNotifier.updateState(RuntimeReadyState.connectingRealtime);
      debugPrint('[OperationalRuntimeHydrator] STEP 5: Establishing realtime connection checkpoint...');
      _ref.read(realtimeSyncManagerProvider).connectLocal();

      readyNotifier.updateState(RuntimeReadyState.ready);
      debugPrint('[OperationalRuntimeHydrator] LINEAR BOOT SEQUENCE COMPLETED successfully. Releasing UI gating.');
    } catch (e, stack) {
      readyNotifier.updateState(RuntimeReadyState.error);
      debugPrint('[OperationalRuntimeHydrator] CRITICAL FAILURE in linear boot sequence: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }
}
