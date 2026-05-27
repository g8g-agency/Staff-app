// lib/features/onboarding/data/repositories/onboarding_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/entities/onboarding_status_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return OnboardingRepository(dio);
});

class OnboardingRepository {
  final Dio _dio;

  OnboardingRepository(this._dio);

  Future<OnboardingStatusModel> getOnboardingStatus() async {
    try {
      final response = await _dio.get('/v1/admin/onboarding/status');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return OnboardingStatusModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to fetch onboarding status: ${response.data['error']}');
    } catch (e) {
      throw Exception('Network error while fetching onboarding status: $e');
    }
  }
}
