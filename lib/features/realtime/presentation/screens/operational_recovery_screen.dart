// lib/features/realtime/presentation/screens/operational_recovery_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../state/realtime_providers.dart';

class OperationalRecoveryScreen extends ConsumerStatefulWidget {
  const OperationalRecoveryScreen({super.key});

  @override
  ConsumerState<OperationalRecoveryScreen> createState() => _OperationalRecoveryScreenState();
}

class _OperationalRecoveryScreenState extends ConsumerState<OperationalRecoveryScreen> {
  int _currentPhase = 2; // 0: connection, 1: snapshot, 2: replay, 3: validation, 4: resume, 5: completed
  double _progress = 0.45;
  int _eventsRemaining = 47;
  int _eventsReplayed = 23;
  bool _showActions = false;
  bool _detailsExpanded = false;
  Timer? _phaseTimer;
  Timer? _actionTimer;

  @override
  void initState() {
    super.initState();
    _startRecoverySimulation();
  }

  void _startRecoverySimulation() {
    _currentPhase = 2;
    _progress = 0.45;
    _eventsRemaining = 47;
    _eventsReplayed = 23;
    _showActions = false;
    setState(() {});

    _phaseTimer?.cancel();
    _actionTimer?.cancel();

    // Replay phase simulation
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_currentPhase == 2) {
          if (_eventsRemaining > 10) {
            _eventsRemaining -= 7;
            _eventsReplayed += 7;
            _progress = (_eventsReplayed / 70).clamp(0.0, 1.0);
          } else {
            _eventsRemaining = 0;
            _eventsReplayed = 70;
            _progress = 1.0;
            _currentPhase = 3; // Move to validating state
          }
        } else if (_currentPhase == 3) {
          _currentPhase = 4; // Move to resuming operations
        } else if (_currentPhase == 4) {
          _currentPhase = 5; // Completed!
          timer.cancel();
          // Automatically navigate to floor layout / dashboard after 500ms when recovery completes
          Timer(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            ref.read(realtimeStateProvider.notifier).simulateReconnect();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          });
        }
      });
    });

    // Show actions after 3s simulated delay
    _actionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showActions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _actionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // ── Header Logo & Title ──────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Restoring Operational Data',
                style: AppTextStyles.h2.copyWith(color: textPrimary, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We detected a gap in real-time events. Your floor data is being restored safely.',
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),

              // ── Stepper Phases ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStepperItem(
                        index: 0,
                        title: 'Connection Restored',
                        isDone: _currentPhase > 0,
                        isActive: _currentPhase == 0,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildStepConnector(isDone: _currentPhase > 0, borderColor: borderColor),
                      _buildStepperItem(
                        index: 1,
                        title: 'Fetching Snapshot',
                        isDone: _currentPhase > 1,
                        isActive: _currentPhase == 1,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildStepConnector(isDone: _currentPhase > 1, borderColor: borderColor),
                      _buildStepperItem(
                        index: 2,
                        title: 'Replaying Events',
                        subtitle: _currentPhase == 2 ? '$_eventsRemaining events remaining' : null,
                        isDone: _currentPhase > 2,
                        isActive: _currentPhase == 2,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildStepConnector(isDone: _currentPhase > 2, borderColor: borderColor),
                      _buildStepperItem(
                        index: 3,
                        title: 'Validating State',
                        isDone: _currentPhase > 3,
                        isActive: _currentPhase == 3,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildStepConnector(isDone: _currentPhase > 3, borderColor: borderColor),
                      _buildStepperItem(
                        index: 4,
                        title: 'Resuming Operations',
                        isDone: _currentPhase > 4,
                        isActive: _currentPhase == 4,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      
                      const SizedBox(height: 32),

                      // ── Progress Bar ─────────────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Safety Note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Your floor data is protected. No actions were lost.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ── Expandable Details ────────────────────────────────────
                      _buildRecoveryDetails(surfaceColor, borderColor, textPrimary, textSecondary),
                    ],
                  ),
                ),
              ),

              // ── Actions Area ─────────────────────────────────────────────
              if (_showActions) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'Retry Recovery',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _startRecoverySimulation();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        child: Text(
                          'Continue with Cached Data',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Simulates continuing with local state
                          ref.read(realtimeStateProvider.notifier).simulateReconnect();
                          context.go('/dashboard');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperItem({
    required int index,
    required String title,
    String? subtitle,
    required bool isDone,
    required bool isActive,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color iconColor;
    Widget iconWidget;

    if (isDone) {
      iconColor = AppColors.success;
      iconWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (isActive) {
      iconColor = AppColors.warning;
      iconWidget = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      iconColor = Colors.grey;
      iconWidget = Text(
        '${index + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor,
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isDarkened(index) ? FontWeight.normal : FontWeight.bold,
                  color: isDarkened(index) ? textSecondary : textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool isDarkened(int index) {
    if (_currentPhase == 5) return false;
    return index > _currentPhase;
  }

  Widget _buildStepConnector({required bool isDone, required Color borderColor}) {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      height: 20,
      width: 2,
      color: isDone ? AppColors.success : borderColor,
    );
  }

  Widget _buildRecoveryDetails(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Recovery Details',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            trailing: Icon(
              _detailsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: textSecondary,
            ),
            onTap: () {
              setState(() {
                _detailsExpanded = !_detailsExpanded;
              });
            },
          ),
          if (_detailsExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Events replayed', '$_eventsReplayed / 70', textSecondary),
                  const SizedBox(height: 8),
                  _buildDetailRow('Snapshot age', '8 min ago', textSecondary),
                  const SizedBox(height: 8),
                  _buildDetailRow('Last known event', '7 min ago', textSecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
        Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
