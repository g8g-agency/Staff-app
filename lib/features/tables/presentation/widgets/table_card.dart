// lib/features/tables/presentation/widgets/table_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../../../core/theme/app_colors.dart';

class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final Function(TableStatus) onStatusChange;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onStatusChange,
  });

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.success;
      case TableStatus.occupied:
        return AppColors.primary;
      case TableStatus.reserved:
        return AppColors.secondary;
      case TableStatus.needsAttention:
        return AppColors.error;
      case TableStatus.cleaning:
        return Colors.blueAccent;
      case TableStatus.unknown:
      case TableStatus.projectionPending:
      case TableStatus.recovering:
        return Colors.grey;
    }
  }

  String _getStatusLabel(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.needsAttention:
        return 'Alert';
      case TableStatus.cleaning:
        return 'Cleaning';
      case TableStatus.unknown:
        return 'Unknown';
      case TableStatus.projectionPending:
        return 'Pending';
      case TableStatus.recovering:
        return 'Recovering';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(table.status);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkSurface,
                      AppColors.darkSurfaceCard,
                    ]
                  : [
                      Colors.white,
                      AppColors.lightSurfaceCard,
                    ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Top accent status glow
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(color: statusColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              table.label,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusLabel(table.status),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Seats: ${table.capacity}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dropdown / Quick Action status changer
                          Text(
                            table.activeOrderId != null ? 'Order Active' : 'No Order',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: table.activeOrderId != null
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          PopupMenuButton<TableStatus>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            onSelected: onStatusChange,
                            itemBuilder: (context) => TableStatus.values
                                .map((status) => PopupMenuItem(
                                      value: status,
                                      child: Text(_getStatusLabel(status)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
