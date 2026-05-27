// lib/features/onboarding/presentation/screens/setup_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/onboarding_notifier.dart';
import '../../../auth/presentation/state/auth_notifier.dart';

class SetupDashboardScreen extends ConsumerWidget {
  const SetupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: onboardingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load setup status: $err'),
              TextButton(
                onPressed: () => ref.read(onboardingNotifierProvider.notifier).hydrate(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (status) {
          if (status == null) {
            return const Center(child: Text('Initializing...'));
          }

          // Calculate completion percentage
          int completed = 0;
          if (status.hasCategories) completed++;
          if (status.hasMenuItems) completed++;
          if (status.hasTaxProfiles) completed++;
          if (status.hasTables) completed++;
          if (status.hasStaff) completed++;
          if (status.hasKdsStations) completed++;
          
          final progress = completed / 6.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Orderlli, ${authState.loggedInStaff?.name ?? 'Owner'}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s get your restaurant ready for operations. Complete these essential setup steps to start taking orders.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Progress Overview
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Setup Progress',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stage: ${status.setupStage.replaceAll('_', ' ')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Checklist Cards
                    Text(
                      'Setup Checklist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    _ChecklistCard(
                      title: 'Create First Menu Category',
                      description: 'Group your items (e.g. Starters, Mains, Drinks)',
                      isCompleted: status.hasCategories,
                      icon: Icons.category_rounded,
                      onTap: () {
                        // In a real app this would route to the category management screen.
                        // Currently, these screens might need to be created or we just navigate to a placeholder.
                        context.push('/menu-setup/categories');
                      },
                    ),
                    _ChecklistCard(
                      title: 'Add Menu Items',
                      description: 'Add your dishes with prices and details',
                      isCompleted: status.hasMenuItems,
                      icon: Icons.restaurant_menu_rounded,
                      onTap: () {
                        context.push('/menu-setup/items');
                      },
                    ),
                    _ChecklistCard(
                      title: 'Configure Taxes',
                      description: 'Set up GST, VAT or other local tax profiles',
                      isCompleted: status.hasTaxProfiles,
                      icon: Icons.request_quote_rounded,
                      onTap: () {
                        context.push('/tax-setup');
                      },
                    ),
                    _ChecklistCard(
                      title: 'Create Tables',
                      description: 'Map out your restaurant floor plan',
                      isCompleted: status.hasTables,
                      icon: Icons.table_restaurant_rounded,
                      onTap: () {
                        context.push('/tables-setup');
                      },
                    ),
                    _ChecklistCard(
                      title: 'Invite Staff',
                      description: 'Add waiters, chefs, and managers',
                      isCompleted: status.hasStaff,
                      icon: Icons.people_rounded,
                      onTap: () {
                        context.push('/staff-setup');
                      },
                    ),
                    _ChecklistCard(
                      title: 'Configure Kitchen Stations',
                      description: 'Set up KDS routing for your kitchen',
                      isCompleted: status.hasKdsStations,
                      icon: Icons.kitchen_rounded,
                      onTap: () {
                        context.push('/kds-setup');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isCompleted;
  final IconData icon;
  final VoidCallback onTap;

  const _ChecklistCard({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isCompleted ? AppColors.success.withValues(alpha: 0.2) : AppColors.background,
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: isCompleted ? AppColors.success : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: isCompleted ? Colors.grey : Colors.grey[400],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
