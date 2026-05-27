// lib/features/tables/presentation/screens/table_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/state/active_order_notifier.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../domain/entities/restaurant_table.dart';
import '../state/table_grid_notifier.dart';

class TableDetailScreen extends ConsumerWidget {
  final String tableId;

  const TableDetailScreen({
    super.key,
    required this.tableId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrderAsync = ref.watch(activeOrderNotifierProvider(tableId));
    final tableGridStateAsync = ref.watch(tableGridNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Table $tableId Details'),
      ),
      body: tableGridStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error loading layout: $err')),
        data: (gridState) {
          final tableIndex = gridState.tables.indexWhere((t) => t.id == tableId);
          if (tableIndex == -1) {
            return Center(child: Text('Table $tableId not found.'));
          }
          final table = gridState.tables[tableIndex];

          return activeOrderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Error loading active session: $err')),
            data: (order) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table General Header Card
                    _buildTableHeaderCard(table, theme, isDark),
                    const SizedBox(height: 24),

                    // Active Order Session Info
                    Expanded(
                      child: _buildSessionBody(context, ref, table, order, theme, isDark),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTableHeaderCard(RestaurantTable table, ThemeData theme, bool isDark) {
    Color statusColor;
    switch (table.status) {
      case TableStatus.available:
        statusColor = AppColors.success;
        break;
      case TableStatus.occupied:
        statusColor = AppColors.primary;
        break;
      case TableStatus.reserved:
        statusColor = AppColors.warning;
        break;
      case TableStatus.needsAttention:
        statusColor = AppColors.error;
        break;
      case TableStatus.cleaning:
        statusColor = Colors.grey;
        break;
      case TableStatus.unknown:
      case TableStatus.projectionPending:
      case TableStatus.recovering:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${table.label}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacity: ${table.capacity} guests',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Text(
                table.status.name.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBody(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    Order? order,
    ThemeData theme,
    bool isDark,
  ) {
    // If table is available, show "Seat Table" action
    if (order == null || table.status == TableStatus.available || table.status == TableStatus.cleaning) {
      return Center(
        key: const ValueKey('seat-table-view'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              table.status == TableStatus.cleaning ? Icons.cleaning_services_rounded : Icons.table_restaurant_rounded,
              size: 72,
              color: AppColors.info,
            ),
            const SizedBox(height: 16),
            Text(
              table.status == TableStatus.cleaning
                  ? 'Table is currently being cleaned.'
                  : 'Table is clean and available for seating.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.sensor_occupied_rounded),
              label: const Text('Seat Guests & Create Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                // Initialize Order
                await ref.read(activeOrderNotifierProvider(tableId).notifier).createOrder();
                // Route to Order Editor
                if (context.mounted) {
                  await context.push('/tables/$tableId/edit');
                }
              },
            ),
          ],
        ),
      );
    }

    // Active session details
    final foodReadyCount = order.items.where((i) => i.status == OrderItemStatus.ready).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Seated Order Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (foodReadyCount > 0)
              GestureDetector(
                onTap: () async {
                  // Mark all ready items as served
                  final readyItems = order.items.where((i) => i.status == OrderItemStatus.ready).toList();
                  final notifier = ref.read(activeOrderNotifierProvider(tableId).notifier);
                  for (final item in readyItems) {
                    await notifier.updateItemQuantity(item.id, item.quantity); // Re-trigger update to flush
                  }
                  // Clear needs attention alert back to occupied
                  await notifier.clearAlert();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$foodReadyCount Dishes Ready to Serve!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Seat ${item.seatNumber} • Status: ${item.status.name.toUpperCase()}'),
                  trailing: Text(item.totalPrice.formatted, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Edit Order'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.push('/tables/$tableId/edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.call_split_rounded),
                label: const Text('Split Table'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.push('/tables/$tableId/split'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.push('/tables/$tableId/pay'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
