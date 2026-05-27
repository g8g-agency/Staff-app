// lib/features/onboarding/domain/entities/onboarding_status_model.dart

class OnboardingStatusModel {
  final String tenantId;
  final bool hasCategories;
  final bool hasMenuItems;
  final bool hasTaxProfiles;
  final bool hasTables;
  final bool hasStaff;
  final bool hasKdsStations;
  final String setupStage;
  final bool isOperational;

  const OnboardingStatusModel({
    required this.tenantId,
    required this.hasCategories,
    required this.hasMenuItems,
    required this.hasTaxProfiles,
    required this.hasTables,
    required this.hasStaff,
    required this.hasKdsStations,
    required this.setupStage,
    required this.isOperational,
  });

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusModel(
      tenantId: json['tenant_id'] as String? ?? '',
      hasCategories: json['has_categories'] as bool? ?? false,
      hasMenuItems: json['has_menu_items'] as bool? ?? false,
      hasTaxProfiles: json['has_tax_profiles'] as bool? ?? false,
      hasTables: json['has_tables'] as bool? ?? false,
      hasStaff: json['has_staff'] as bool? ?? false,
      hasKdsStations: json['has_kds_stations'] as bool? ?? false,
      setupStage: json['setup_stage'] as String? ?? 'EMPTY',
      isOperational: json['is_operational'] as bool? ?? false,
    );
  }
}
