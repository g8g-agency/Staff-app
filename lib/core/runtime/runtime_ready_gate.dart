// lib/core/runtime/runtime_ready_gate.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RuntimeReadyState {
  initializing,
  authenticating,
  hydratingContext,
  fetchingSnapshot,
  seedingProjections,
  validatingChecksums,
  connectingRealtime,
  ready,
  error,
}

class RuntimeReadyNotifier extends StateNotifier<RuntimeReadyState> {
  RuntimeReadyNotifier() : super(RuntimeReadyState.initializing);

  void updateState(RuntimeReadyState newState) {
    debugPrint('[RuntimeReadyGate] Transitioning to: $newState');
    state = newState;
  }

  bool get isReady => state == RuntimeReadyState.ready;
}

final runtimeReadyProvider = StateNotifierProvider<RuntimeReadyNotifier, RuntimeReadyState>((ref) {
  return RuntimeReadyNotifier();
});

/// Extends standard ProviderRef with security asserts to prevent early un-hydrated accesses.
extension RuntimeReadyGuard on Ref {
  void assertRuntimeReady() {
    final readyState = read(runtimeReadyProvider);
    if (readyState != RuntimeReadyState.ready) {
      throw StateError(
        '[RuntimeReadyGate] Security Violation: Attempted to read un-hydrated context before hydration sequence completed. '
        'Current State: $readyState'
      );
    }
  }
}
