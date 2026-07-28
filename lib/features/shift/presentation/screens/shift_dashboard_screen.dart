// lib/features/shift/presentation/screens/shift_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

// Real data providers
import '../../../auth/presentation/state/auth_notifier.dart';
import '../../../orders/presentation/state/orders_projection_provider.dart';
import '../../../tables/presentation/state/table_grid_notifier.dart';
import '../../../waiter_calls/presentation/state/waiter_calls_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../auth/domain/entities/staff_member.dart';

// Re-export shift entities for use in this file
export '../../domain/entities/shift_session.dart' show ShiftStatus;
import '../../domain/entities/shift_session.dart';
import '../../../../core/network/sync_state.dart';

// ─── Local view models ────────────────────────────────────────────────────────

class _WorkloadItem {
  final String tableId;
  final String tableLabel;
  final String orderStatus; // 'preparing' | 'ready' | 'pending_payment'
  final DateTime orderStartedAt;
  final int slaTargetMinutes;

  const _WorkloadItem({
    required this.tableId,
    required this.tableLabel,
    required this.orderStatus,
    required this.orderStartedAt,
    this.slaTargetMinutes = 20,
  });

  int get elapsedMinutes => DateTime.now().difference(orderStartedAt).inMinutes;
  double get slaProgress => (elapsedMinutes / slaTargetMinutes).clamp(0.0, 1.0);
  bool get isSlaBreached => elapsedMinutes > slaTargetMinutes;
  Color get slaColor {
    if (slaProgress < 0.6) return AppColors.success;
    if (slaProgress < 0.85) return AppColors.warning;
    return AppColors.error;
  }
}

class _ColleagueOverload {
  final String staffId;
  final String name;
  final int activeTableCount;
  _ColleagueOverload({required this.staffId, required this.name, required this.activeTableCount});
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ShiftDashboardScreen extends ConsumerStatefulWidget {
  const ShiftDashboardScreen({super.key});

  @override
  ConsumerState<ShiftDashboardScreen> createState() => _ShiftDashboardScreenState();
}

class _ShiftDashboardScreenState extends ConsumerState<ShiftDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker((_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Derived workload from real orders + tables ────────────────────────────

  List<_WorkloadItem> _buildWorkload(
    List<Order> orders,
    List<RestaurantTable> tables,
    String? myStaffId,
  ) {
    // Map tableId -> label from the real tables list
    final tableLabels = {for (final t in tables) t.id: t.label};

    // Filter orders that are active (preparing / ready / pending payment)
    // and optionally assigned to the current waiter
    final activeStatuses = {
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.sent,
    };

    return orders
        .where((o) => activeStatuses.contains(o.status))
        .map((o) {
          final label = tableLabels[o.tableId] ?? 'Table ${o.tableId.substring(0, 6)}';
          final String orderStatus;
          if (o.status == OrderStatus.preparing || o.status == OrderStatus.sent) {
            orderStatus = 'preparing';
          } else if (o.status == OrderStatus.ready) {
            // Check if payment was requested
            orderStatus = o.isPaymentRequested ? 'pending_payment' : 'ready';
          } else {
            orderStatus = 'preparing';
          }
          return _WorkloadItem(
            tableId: o.tableId,
            tableLabel: label,
            orderStatus: orderStatus,
            orderStartedAt: o.createdAt,
          );
        })
        .toList();
  }

  // ── Colleague overload detection ──────────────────────────────────────────

  List<_ColleagueOverload> _buildColleagueOverloads(
    List<StaffMember> allStaff,
    List<Order> orders,
    List<RestaurantTable> tables,
    String? myStaffId,
  ) {
    // Count occupied tables per waiter by looking at waiterName on active orders
    final Map<String, int> tableCountByStaff = {};
    final Map<String, String> staffNameById = {};
    for (final s in allStaff) {
      staffNameById[s.id] = s.name;
    }

    // Count unique table IDs per waiter name
    final activeStatuses = {
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.sent,
    };
    final Map<String, Set<String>> tablesByWaiterName = {};
    for (final o in orders) {
      if (activeStatuses.contains(o.status) && o.waiterName.isNotEmpty) {
        tablesByWaiterName.putIfAbsent(o.waiterName, () => {}).add(o.tableId);
      }
    }

    // Look for staff with 5+ active tables (overloaded), who are not me
    const overloadThreshold = 5;
    final result = <_ColleagueOverload>[];
    for (final entry in tablesByWaiterName.entries) {
      final name = entry.key;
      final count = entry.value.length;
      if (count >= overloadThreshold) {
        // Find staff member by name (best effort)
        final staffEntry = allStaff
            .where((s) => s.name == name || '${s.firstName} ${s.lastName}'.trim() == name)
            .firstOrNull;
        final sid = staffEntry?.id ?? name;
        if (sid != myStaffId) {
          result.add(_ColleagueOverload(staffId: sid, name: name, activeTableCount: count));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final staff = authState.loggedInStaff;
    final shiftStartTime = authState.shiftStartTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real data
    final ordersAsync = ref.watch(ordersProjectionProvider);
    final tablesAsync = ref.watch(tableGridNotifierProvider);
    final waiterCallsAsync = ref.watch(activeWaiterCallsProvider);
    final allStaff = ref.watch(authNotifierProvider.notifier).mockStaff;

    final orders = ordersAsync; // List<Order>
    final tables = tablesAsync.maybeWhen(
      data: (state) => state.tables,
      orElse: () => <RestaurantTable>[],
    );

    // Shift elapsed time
    final shiftStart = shiftStartTime ?? DateTime.now();
    final elapsed = DateTime.now().difference(shiftStart);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    // Derive metrics
    final workload = _buildWorkload(orders, tables, staff?.id);
    final overloads = _buildColleagueOverloads(allStaff, orders, tables, staff?.id);
    final activeTableCount = tables.where((t) => t.status == TableStatus.occupied).length;
    final completedOrderCount = orders.where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.delivered).length;
    final activeOrderCount = workload.length;
    final pendingCallCount = waiterCallsAsync.length;

    // SLA: percentage of non-breached active workload items
    final slaCompliance = workload.isEmpty
        ? 1.0
        : workload.where((w) => !w.isSlaBreached).length / workload.length;

    final staffName = staff?.name.isNotEmpty == true
        ? staff!.name
        : (staff?.firstName.isNotEmpty == true ? '${staff!.firstName} ${staff.lastName}'.trim() : 'Staff');

    final shiftStatus = authState.isShiftStarted ? ShiftStatus.active : ShiftStatus.idle;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, staffName, shiftStatus, h, m, s, isDark),
          SliverToBoxAdapter(
            child: _buildMetricsRow(
              context,
              activeTableCount: activeTableCount,
              completedOrderCount: completedOrderCount,
              activeOrderCount: activeOrderCount,
              pendingCallCount: pendingCallCount,
              isDark: isDark,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'My Active Workload',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          workload.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyWorkload(context))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _WorkloadCard(item: workload[i]),
                    ),
                    childCount: workload.length,
                  ),
                ),
          SliverToBoxAdapter(
            child: _buildBranchAwareness(context, overloads, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildProgressBar(context, slaCompliance, completedOrderCount, isDark),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    String staffName,
    ShiftStatus status,
    String h,
    String m,
    String s,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.95),
                AppColors.secondary.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shift Dashboard',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              staffName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShiftStatusBadge(status: status),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$h:$m:$s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontFeatures: [FontFeature.tabularFigures()],
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
    );
  }

  Widget _buildMetricsRow(
    BuildContext context, {
    required int activeTableCount,
    required int completedOrderCount,
    required int activeOrderCount,
    required int pendingCallCount,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _MetricChip(
              icon: Icons.table_restaurant_rounded,
              label: 'Tables',
              value: '$activeTableCount',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _MetricChip(
              icon: Icons.check_circle_rounded,
              label: 'Completed',
              value: '$completedOrderCount',
              color: AppColors.success,
            ),
            const SizedBox(width: 10),
            _MetricChip(
              icon: Icons.receipt_long_rounded,
              label: 'Active Orders',
              value: '$activeOrderCount',
              color: AppColors.secondary,
              pulse: activeOrderCount > 0,
            ),
            const SizedBox(width: 10),
            _MetricChip(
              icon: Icons.support_agent_rounded,
              label: 'Pending Calls',
              value: '$pendingCallCount',
              color: pendingCallCount > 0 ? AppColors.error : AppColors.success,
              pulse: pendingCallCount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkload(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          const Text('No active tables assigned', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Your workload is clear', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildBranchAwareness(BuildContext context, List<_ColleagueOverload> overloads, bool isDark) {
    if (overloads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.groups_rounded, size: 18, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Colleague Overload Alert',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.warning)),
            ]),
            const SizedBox(height: 10),
            ...overloads.map((o) => Row(children: [
                  const Icon(Icons.person_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${o.name} — ${o.activeTableCount} active tables',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildHelperButton(context, o),
                ])),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperButton(BuildContext context, _ColleagueOverload o) {
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer to assist ${o.name}? Notify supervisor.')),
        );
      },
      child: const Text('Assist', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildProgressBar(BuildContext context, double sla, int completedOrderCount, bool isDark) {
    final slaColor = sla >= 0.9 ? AppColors.success : sla >= 0.7 ? AppColors.warning : AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shift SLA Performance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${(sla * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: slaColor),
                ),
                const SizedBox(width: 8),
                Text('compliance', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: sla,
                minHeight: 10,
                backgroundColor: slaColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(slaColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedOrderCount orders completed this shift',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ShiftStatusBadge extends StatelessWidget {
  final ShiftStatus status;
  const _ShiftStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ShiftStatus.active => 'ACTIVE',
      ShiftStatus.paused => 'PAUSED',
      ShiftStatus.closing => 'CLOSING',
      _ => 'IDLE',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool pulse;
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  final _WorkloadItem item;
  const _WorkloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slaColor = item.slaColor;
    final statusIcon = switch (item.orderStatus) {
      'preparing' => Icons.restaurant_rounded,
      'ready' => Icons.delivery_dining_rounded,
      'pending_payment' => Icons.account_balance_wallet_rounded,
      _ => Icons.table_restaurant_rounded,
    };
    final statusLabel = switch (item.orderStatus) {
      'preparing' => 'Preparing',
      'ready' => 'Ready for pickup',
      'pending_payment' => 'Payment pending',
      _ => item.orderStatus,
    };
    final statusColor = switch (item.orderStatus) {
      'preparing' => AppColors.warning,
      'ready' => AppColors.success,
      'pending_payment' => const Color(0xFF8B5CF6),
      _ => AppColors.primary,
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isSlaBreached
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_restaurant_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.tableLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.elapsedMinutes}m',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: slaColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.slaProgress,
              minHeight: 6,
              backgroundColor: slaColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(slaColor),
            ),
          ),
          if (item.isSlaBreached) ...[
            const SizedBox(height: 6),
            Text(
              'SLA breached — ${item.elapsedMinutes - item.slaTargetMinutes}m over target',
              style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
