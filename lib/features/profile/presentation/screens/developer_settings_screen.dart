import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/state/auth_notifier.dart';

class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final authState = ref.watch(authNotifierProvider);
    final staff = authState.loggedInStaff;
    final isDeveloperModeEnabled = staff?.developerModeEnabled ?? false;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Developer Options',
          style: AppTextStyles.h3.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Configure debugging, diagnostics and operational runtime visibility.',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer Mode',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable advanced runtime observability',
                            style: AppTextStyles.caption.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: isDeveloperModeEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (value) async {
                          HapticFeedback.mediumImpact();
                          if (staff != null) {
                            // Call provider to update the staff record in DB.
                            // Assuming an update function exists, we mock it for now.
                            // In a real implementation this sends an API request/Supabase update.
                            final updatedStaff = staff.copyWith(developerModeEnabled: value);
                            ref.read(authNotifierProvider.notifier).updateStaffSession(updatedStaff);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (isDeveloperModeEnabled) ...[
                  Divider(height: 1, indent: 16, color: borderColor),
                  ListTile(
                    title: Text(
                      'Open Developer Dashboard',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                    onTap: () {
                      context.push('/developer');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
