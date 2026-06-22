// lib/features/orders/services/orders_realtime_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RealtimeOrderEventType { insert, update, other }

class RealtimeOrderEvent {
  final RealtimeOrderEventType type;
  final Map<String, dynamic> payload;

  RealtimeOrderEvent(this.type, this.payload);
}

class OrdersRealtimeService {
  final SupabaseClient _supabase;
  final String _branchId;
  
  RealtimeChannel? _channel;
  final _eventController = StreamController<RealtimeOrderEvent>.broadcast();

  OrdersRealtimeService(this._supabase, this._branchId);

  Stream<RealtimeOrderEvent> get onEvent => _eventController.stream;

  void subscribe() {
    if (_channel != null) return;

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'branch_id',
      value: _branchId,
    );
    debugPrint('[OrdersRealtimeService] Subscribing to public.orders for branch $_branchId');

    _channel = _supabase
        .channel('public:orders:branch_$_branchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: filter,
          callback: (payload) {
            final receivedBranchId = payload.newRecord['branch_id'];
            if (receivedBranchId != _branchId) {
              debugPrint('[SECURITY ALERT] Wrong branch order received!');
              debugPrint('  Expected: $_branchId | Got: $receivedBranchId');
              return; // Drop silently
            }

            _eventController.add(RealtimeOrderEvent(
              RealtimeOrderEventType.insert,
              payload.newRecord,
            ));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: filter,
          callback: (payload) {
            debugPrint('[OrdersRealtimeService] RECEIVED PostgresChanges update: ${payload.newRecord}');
            final receivedBranchId = payload.newRecord['branch_id'];
            if (receivedBranchId != _branchId) {
              debugPrint('[SECURITY ALERT] Wrong branch update received!');
              return;
            }

            _eventController.add(RealtimeOrderEvent(
              RealtimeOrderEventType.update,
              payload.newRecord,
            ));
          },
        );

    _channel?.subscribe((status, [error]) {
      debugPrint('[OrdersRealtimeService] Subscription status: $status');
    });
  }

  void dispose() {
    debugPrint('[OrdersRealtimeService] Disposing subscription');
    _channel?.unsubscribe();
    _channel = null;
    _eventController.close();
  }
}
