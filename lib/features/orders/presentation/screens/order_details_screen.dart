// lib/features/orders/presentation/screens/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../providers/orders_providers.dart';
import '../state/active_order_notifier.dart';
import '../../../tables/presentation/state/table_grid_notifier.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(ordersRepositoryProvider);

    return StreamBuilder<Order?>(
      stream: repository.watchOrderById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              title: const Text('Order Details'),
            ),
            body: const Center(child: Text('Order not found.')),
          );
        }

        return Consumer(
          builder: (context, ref, _) {
            final tablesAsync = ref.watch(tableGridNotifierProvider);
            final tableLabel = tablesAsync.valueOrNull?.tables
                    .where((t) => t.id == order.tableId)
                    .firstOrNull
                    ?.label ??
                'Table ${order.tableId.substring(0, 4).toUpperCase()}';

            return _OrderDetailsContent(
              order: order,
              tableLabel: tableLabel,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content widget
// ─────────────────────────────────────────────────────────────────────────────

class _OrderDetailsContent extends ConsumerWidget {
  final Order order;
  final String tableLabel;
  const _OrderDetailsContent({required this.order, required this.tableLabel});

  // ── Status config ──────────────────────────────────────────────────────────

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.draft => const Color(0xFF64748B),
        OrderStatus.sent => const Color(0xFF3B82F6),
        OrderStatus.preparing => const Color(0xFFF59E0B),
        OrderStatus.ready => const Color(0xFF10B981),
        OrderStatus.delivered => const Color(0xFF8B5CF6),
        OrderStatus.completed => const Color(0xFF22C55E),
        OrderStatus.cancelled => const Color(0xFFEF4444),
      };

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.draft => 'Draft',
        OrderStatus.sent => 'Sent to KDS',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  IconData _statusIcon(OrderStatus s) => switch (s) {
        OrderStatus.draft => Icons.edit_note_rounded,
        OrderStatus.sent => Icons.send_rounded,
        OrderStatus.preparing => Icons.restaurant_rounded,
        OrderStatus.ready => Icons.done_all_rounded,
        OrderStatus.delivered => Icons.delivery_dining_rounded,
        OrderStatus.completed => Icons.check_circle_rounded,
        OrderStatus.cancelled => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderNumber = order.id.substring(0, 8).toUpperCase();
    final statusColor = _statusColor(order.status);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF3F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF3F4F8),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withValues(alpha: 0.85),
                      AppColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(64, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tableLabel,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'ORD-$orderNumber',
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Live status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(order.status), color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    _statusLabel(order.status),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // KDS sync indicator
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'KDS Synced',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body cards ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusTimeline(context, isDark),
                const SizedBox(height: 14),
                _buildOrderSummaryRow(context, isDark),
                const SizedBox(height: 14),
                _buildWaiterCard(context, isDark),
                const SizedBox(height: 14),
                _buildItemsCard(context, ref, isDark),
                if (order.cancelLogs.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildCancelLogsCard(context, isDark),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status timeline ────────────────────────────────────────────────────────

  Widget _buildStatusTimeline(BuildContext context, bool isDark) {
    final stages = [
      OrderStatus.draft,
      OrderStatus.sent,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];
    final currentIdx = stages.indexOf(order.status);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Order Flow', icon: Icons.timeline_rounded),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stages.length, (i) {
              final isDone = i <= currentIdx;
              final isActive = i == currentIdx;
              final color = _statusColor(stages[i]);
              final label = switch (stages[i]) {
                OrderStatus.draft => 'Draft',
                OrderStatus.sent => 'KDS',
                OrderStatus.preparing => 'Cooking',
                OrderStatus.ready => 'Ready',
                _ => 'Done',
              };

              return Expanded(
                child: Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: isDone
                                ? LinearGradient(colors: [
                                    _statusColor(stages[i - 1]),
                                    color,
                                  ])
                                : null,
                            color: isDone ? null : Colors.white12,
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 32 : 26,
                          height: isActive ? 32 : 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? color : Colors.white10,
                            border: isActive
                                ? Border.all(color: color.withValues(alpha: 0.5), width: 3)
                                : null,
                            boxShadow: isActive
                                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
                                : [],
                          ),
                          child: Center(
                            child: isDone && !isActive
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : Icon(
                                    _statusIcon(stages[i]),
                                    size: 13,
                                    color: isDone ? Colors.white : Colors.white24,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isDone ? color : Colors.white30,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (i < stages.length - 1) const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Order summary row: total / items / time ────────────────────────────────

  Widget _buildOrderSummaryRow(BuildContext context, bool isDark) {
    final elapsed = DateTime.now().difference(order.createdAt);
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m ago'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';
    final activeItems = order.items.where((i) => i.status != OrderItemStatus.cancelled).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total',
            value: order.totalPrice.formatted,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_rounded,
            label: 'Items',
            value: '$activeItems',
            color: const Color(0xFF4ECDC4),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            label: 'Age',
            value: elapsedStr,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ── Waiter card (no transfer button) ──────────────────────────────────────

  Widget _buildWaiterCard(BuildContext context, bool isDark) {
    final name = order.waiterName.isNotEmpty ? order.waiterName : 'Unassigned';
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return _Card(
      isDark: isDark,
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Waiter',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Status dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: AppColors.success, size: 7),
                const SizedBox(width: 5),
                Text(
                  'Active',
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items list ─────────────────────────────────────────────────────────────

  Widget _buildItemsCard(BuildContext context, WidgetRef ref, bool isDark) {
    final groupedItems = <int, List<OrderItem>>{};
    for (final item in order.items) {
      groupedItems.putIfAbsent(item.seatNumber, () => []).add(item);
    }
    final sortedSeats = groupedItems.keys.toList()..sort();

    return _Card(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                _SectionTitle(title: 'Order Items', icon: Icons.restaurant_menu_rounded),
                const Spacer(),
                Text(
                  order.totalPrice.formatted,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No items in this order.')),
            )
          else
            ...sortedSeats.map((seat) {
              final seatItems = groupedItems[seat]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seat header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.chair_rounded, size: 13, color: Colors.white38),
                        const SizedBox(width: 5),
                        Text(
                          'Seat $seat',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...seatItems.map((item) => _buildItemRow(context, ref, item, isDark)),
                ],
              );
            }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, WidgetRef ref, OrderItem item, bool isDark) {
    final isCancelled = item.status == OrderItemStatus.cancelled;
    final itemStatusColor = switch (item.status) {
      OrderItemStatus.queued => const Color(0xFF64748B),
      OrderItemStatus.preparing => const Color(0xFFF59E0B),
      OrderItemStatus.ready => const Color(0xFF10B981),
      OrderItemStatus.served => const Color(0xFF8B5CF6),
      OrderItemStatus.cancelled => const Color(0xFFEF4444),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      decoration: BoxDecoration(
        color: isCancelled
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: isCancelled ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Qty badge
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isCancelled ? Colors.white24 : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + modifiers + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCancelled ? Colors.white30 : Colors.white,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedModifiers.isNotEmpty)
                    Text(
                      item.selectedModifiers.map((m) => m.name).join(', '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white38,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: itemStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.status.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: itemStatusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Price + cancel button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.totalPrice.formatted,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? Colors.white24 : Colors.white70,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isCancelled) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showCancelItemDialog(context, ref, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelItemDialog(BuildContext context, WidgetRef ref, OrderItem item) {
    final controller = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cancel Item',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                item.product.name,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Reason (e.g. Guest changed mind)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Back', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final reason = controller.text.trim();
                        if (reason.isNotEmpty) {
                          ref.read(activeOrderNotifierProvider(order.tableId).notifier).cancelItem(item.id, reason);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.product.name} cancelled'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text('Confirm Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancel logs ────────────────────────────────────────────────────────────

  Widget _buildCancelLogsCard(BuildContext context, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Cancellation Log', icon: Icons.assignment_late_rounded),
          const SizedBox(height: 12),
          ...order.cancelLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      log,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, required this.isDark, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161626) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
