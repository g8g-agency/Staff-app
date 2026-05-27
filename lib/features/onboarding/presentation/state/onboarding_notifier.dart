// lib/features/onboarding/presentation/state/onboarding_notifier.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/onboarding_status_model.dart';
import '../../data/repositories/onboarding_repository.dart';

part 'onboarding_notifier.g.dart';

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  AsyncValue<OnboardingStatusModel?> build() {
    return const AsyncValue.data(null);
  }

  /// Hydrate onboarding state ONCE to prevent routing loops and latency spikes.
  Future<void> hydrate() async {
    // Prevent duplicate fetching if already loading or already fetched
    if (state is AsyncLoading || (state.hasValue && state.value != null)) {
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final status = await repo.getOnboardingStatus();
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset when logging out
  void reset() {
    state = const AsyncValue.data(null);
  }
}
