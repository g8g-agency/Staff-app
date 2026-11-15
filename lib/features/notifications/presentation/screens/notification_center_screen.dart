// lib/features/notifications/presentation/screens/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/state/auth_notifier.dart';
import '../../domain/entities/app_notification.dart';
import '../../../orders/domain/entities/order_alert_model.dart';
import '../../../orders/presentation/state/order_alert_notifier.dart';
import '../state/notifications_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      final branchId = authState.selectedBranch?.id;
      final tenantId = authState.selectedOrg?.id ?? '';
      if (branchId != null && tenantId.isNotEmpty) {
        ref.read(orderAlertNotifierProvider.notifier).restorePendingAlerts(
          branchId: branchId,
          tenantId: tenantId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingAlerts = ref.watch(pendingOrderAlertsProvider);
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (pendingAlerts.isEmpty && notifications.isEmpty) {
      return Scaffold(
        body: _buildEmptyState(theme, isDark),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── 1. ACTIVE UNACKNOWLEDGED ORDER ALERTS ────────────────────────
          if (pendingAlerts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'UNACKNOWLEDGED ORDERS (${pendingAlerts.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            ...pendingAlerts.map((alert) => _buildPendingAlertCard(context, alert, theme, isDark)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
          ],

          // ── 2. GENERAL NOTIFICATIONS ────────────────────────────────────
          if (notifications.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOTIFICATIONS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notifications.any((n) => !n.isRead))
                      TextButton.icon(
                        icon: const Icon(Icons.mark_chat_read_rounded, size: 16),
                        label: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(notificationsProvider.notifier).markAllAsRead();
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text('Clear', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(notificationsProvider.notifier).clearAll();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...notifications.map((notif) => Dismissible(
                  key: ValueKey(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(notificationsProvider.notifier).clearNotification(notif.id);
                  },
                  child: _buildNotificationCard(context, ref, notif, theme, isDark),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingAlertCard(
    BuildContext context,
    IncomingOrderAlert alert,
    ThemeData theme,
    bool isDark,
  ) {
    final totalFormatted = (alert.totalAmountMinor / 100).toStringAsFixed(2);
    final itemsSummary = alert.items.isNotEmpty
        ? alert.items.map((i) => '${i.quantity}x ${i.name}').join(', ')
        : '${alert.itemCount} item(s)';

    return Card(
      color: isDark ? const Color(0xFF2B1D1D) : const Color(0xFFFFF5F5),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert.tableNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${alert.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(alert.orderTime),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              itemsSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ₹$totalFormatted',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.amber[300] : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(orderAlertNotifierProvider.notifier).dismissAlert(alert.orderId);
                  },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Claim & Acknowledge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await HapticFeedback.heavyImpact();
                    await ref
                        .read(orderAlertNotifierProvider.notifier)
                        .acceptAlert(alert.orderId, alert.versionNum);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
    ThemeData theme,
    bool isDark,
  ) {
    final Color severityColor;
    final IconData icon;

    switch (notif.severity) {
      case NotificationSeverity.info:
        severityColor = AppColors.success;
        icon = Icons.info_outline_rounded;
        break;
      case NotificationSeverity.warning:
        severityColor = AppColors.secondary;
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationSeverity.urgent:
        severityColor = AppColors.primary;
        icon = Icons.priority_high_rounded;
        break;
      case NotificationSeverity.critical:
        severityColor = AppColors.error;
        icon = Icons.gpp_maybe_rounded;
        break;
    }

    return Card(
      color: notif.isRead
          ? (isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.grey[100])
          : (isDark ? AppColors.darkSurface : Colors.white),
      elevation: notif.isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notif.isRead
              ? Colors.transparent
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(notificationsProvider.notifier).markAsRead(notif.id);
          HapticFeedback.lightImpact();

          if (notif.metadata != null) {
            final tableId = notif.metadata!['tableId'];
            final orderId = notif.metadata!['orderId'];

            if (orderId != null) {
              context.push('/orders/$orderId/details');
            } else if (tableId != null) {
              context.push('/tables/$tableId');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: severityColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              color: notif.isRead ? Colors.grey : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notif.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: notif.isRead
                            ? Colors.grey
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 16),
          Text(
            'Notifications Empty',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Important warnings and calls will show here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}