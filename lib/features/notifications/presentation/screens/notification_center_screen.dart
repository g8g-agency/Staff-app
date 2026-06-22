// lib/features/notifications/presentation/screens/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../state/notifications_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text('$unreadCount'),
                backgroundColor: AppColors.error,
              ),
            ],
          ],
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_rounded),
              tooltip: 'Mark All Read',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(notificationsProvider.notifier).clearAll();
            },
            tooltip: 'Clear All',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(theme, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Dismissible(
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
                );
              },
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
    // Severity theme mappings
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
          // Mark as read
          ref.read(notificationsProvider.notifier).markAsRead(notif.id);
          HapticFeedback.lightImpact();

          // Handle Deep linking logic
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
