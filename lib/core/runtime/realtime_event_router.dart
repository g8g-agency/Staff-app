// lib/core/runtime/realtime_event_router.dart
//
// RealtimeEventRouter — centralized orchestration for ALL realtime events.
// This is the ONLY gateway for websocket payloads entering the runtime.
// Enforces sequence validation, epoch verification, deduplication, and invalidation routing.

import 'package:flutter/foundation.dart';
import 'domain/runtime_event.dart';
import 'domain/invalidation_record.dart';
import 'runtime_epoch_manager.dart';
import 'sequence_validator.dart';
import 'invalidation_coordinator.dart';
import 'branch_isolation_resolver.dart';

/// Callback type for projection rebuild requests.
typedef ProjectionRebuildCallback =
    void Function(List<InvalidationRecord> invalidations);

/// Callback type for post-validation event dispatch.
typedef EventDispatchCallback = Future<void> Function(RuntimeEvent event);

class RealtimeEventRouter {
  final RuntimeEpochManager _epochManager;
  final SequenceValidator _sequenceValidator;
  final InvalidationCoordinator _invalidationCoordinator;
  final BranchIsolationResolver _branchIsolationResolver;

  final Set<String> _processedEventIds = {};
  ProjectionRebuildCallback? _rebuildCallback;
  EventDispatchCallback? _dispatchCallback;

  RealtimeEventRouter({
    required this._epochManager,
    required this._sequenceValidator,
    required this._invalidationCoordinator,
    required this._branchIsolationResolver,
  });

  /// Register the projection rebuild callback.
  void registerRebuildCallback(ProjectionRebuildCallback callback) {
    _rebuildCallback = callback;
    debugPrint('[RealtimeEventRouter] Registered projection rebuild callback');
  }

  /// Register the post-validation event dispatch callback.
  /// Called after an event passes all validation — used to dispatch payloads
  /// to the correct repository/notifier for deterministic state reconstruction.
  void registerDispatchCallback(EventDispatchCallback callback) {
    _dispatchCallback = callback;
    debugPrint('[RealtimeEventRouter] Registered event dispatch callback');
  }

  /// Returns true for push-notification events that do not carry projection
  /// state. These events must bypass epoch/branch validation because the
  /// backend's server_epoch (a Unix timestamp) never matches the client's
  /// UUID-based epoch, and they should reach the staff app regardless of
  /// which branch session is active.
  bool _isAlertEvent(RuntimeEventType type) {
    return type == RuntimeEventType.orderAssigned ||
        type == RuntimeEventType.orderReassigned ||
        type == RuntimeEventType.orderAccepted ||
        type == RuntimeEventType.orderPreparing ||
        type == RuntimeEventType.orderReadyForPickup;
  }

  /// Route a realtime event through the validation pipeline.
  Future<void> routeEvent(RuntimeEvent event) async {
    debugPrint(
      '[RealtimeEventRouter] Routing event: ${event.idempotencyKey} type=${event.type} seq=${event.sequenceNumber}',
    );

    final isAlert = _isAlertEvent(event.type);

    // Step 1: Epoch validation
    // Alert events (ORDER_ASSIGNED, ORDER_REASSIGNED, ORDER_READY_FOR_PICKUP)
    // are push notifications — they carry the backend server_epoch (Unix ms)
    // which will never match the client UUID epoch. Skip this guard for them.
    if (!isAlert && !_epochManager.isEventEpochValid(event.epochId)) {
      debugPrint(
        '[RealtimeEventRouter] REJECTED: Stale epoch ${event.epochId}',
      );
      return;
    }

    // Step 1.5: Branch validation
    // Alert events are targeted notifications — they should be delivered
    // even if the branch resolver has not yet been activated.
    if (!isAlert && !_branchIsolationResolver.isEventBranchValid(event)) {
      debugPrint(
        '[RealtimeEventRouter] REJECTED: Cross-branch state leakage detected. Event branch: ${event.branchId}',
      );
      return;
    }

    // Step 2: Deduplication
    if (_processedEventIds.contains(event.idempotencyKey)) {
      debugPrint(
        '[RealtimeEventRouter] REJECTED: Duplicate event ${event.idempotencyKey}',
      );
      return;
    }

    // Step 3: Sequence validation
    // Alert events share the global branch sequence counter but do not carry
    // projectable state, so ordering is irrelevant. Only dedup matters.
    // We still record the key below (step 4) to prevent duplicates.
    if (!isAlert) {
      final validationResult = _sequenceValidator.validate(event);
      if (!validationResult.isAccepted) {
        debugPrint(
          '[RealtimeEventRouter] REJECTED: Sequence validation failed - ${validationResult.result}',
        );
        return;
      }
    }

    // Step 4: Mark as processed
    _processedEventIds.add(event.idempotencyKey);

    // Step 5: Dispatch payload to correct repository/notifier
    if (_dispatchCallback != null) {
      await _dispatchCallback!(event);
    }

    // Step 6: Compute invalidations
    final invalidations = _invalidationCoordinator.computeInvalidations(event);

    // Step 7: Trigger projection rebuilds
    if (invalidations.isNotEmpty && _rebuildCallback != null) {
      debugPrint(
        '[RealtimeEventRouter] Triggering ${invalidations.length} projection rebuilds',
      );
      _rebuildCallback!(invalidations);
    }

    debugPrint(
      '[RealtimeEventRouter] Event ${event.idempotencyKey} processed successfully',
    );
  }

  /// Route multiple events in batch (for replay or catch-up scenarios).
  Future<void> routeBatch(List<RuntimeEvent> events) async {
    debugPrint(
      '[RealtimeEventRouter] Routing batch of ${events.length} events',
    );

    final validEvents = <RuntimeEvent>[];

    for (final event in events) {
      // Epoch validation
      if (!_epochManager.isEventEpochValid(event.epochId)) {
        debugPrint(
          '[RealtimeEventRouter] REJECTED (batch): Stale epoch ${event.epochId}',
        );
        continue;
      }

      // Deduplication
      if (_processedEventIds.contains(event.idempotencyKey)) {
        debugPrint(
          '[RealtimeEventRouter] REJECTED (batch): Duplicate event ${event.idempotencyKey}',
        );
        continue;
      }

      // Sequence validation
      final validationResult = _sequenceValidator.validate(event);
      if (!validationResult.isAccepted) {
        debugPrint(
          '[RealtimeEventRouter] REJECTED (batch): Sequence validation failed - ${validationResult.result}',
        );
        continue;
      }

      validEvents.add(event);
      _processedEventIds.add(event.idempotencyKey);
    }

    if (validEvents.isEmpty) {
      debugPrint('[RealtimeEventRouter] No valid events in batch');
      return;
    }

    // Batch compute invalidations
    final invalidations = _invalidationCoordinator.computeBatchInvalidations(
      validEvents,
    );

    // Trigger projection rebuilds
    if (invalidations.isNotEmpty && _rebuildCallback != null) {
      debugPrint(
        '[RealtimeEventRouter] Triggering ${invalidations.length} projection rebuilds from batch',
      );
      _rebuildCallback!(invalidations);
    }

    debugPrint(
      '[RealtimeEventRouter] Batch processed: ${validEvents.length} valid events',
    );
  }

  /// Reset router state (for session end or epoch change).
  void reset() {
    _processedEventIds.clear();
    debugPrint('[RealtimeEventRouter] Reset router state');
  }

  /// Get statistics for monitoring.
  Map<String, dynamic> getStats() {
    return {
      'processedEventCount': _processedEventIds.length,
      'hasActiveEpoch': _epochManager.hasActiveEpoch,
      'currentEpochId': _epochManager.currentEpoch.epochId,
    };
  }
}
