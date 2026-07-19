import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/restaurant_table.dart';
import '../state/table_grid_notifier.dart';
import '../../../orders/presentation/state/orders_projection_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/providers/orders_providers.dart';
import '../../../orders/providers/orders_realtime_provider.dart';
import '../../../../shared/models/money.dart';

class TableGridScreen extends ConsumerStatefulWidget {
  const TableGridScreen({super.key});

  @override
  ConsumerState<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends ConsumerState<TableGridScreen> {
  String _selectedZone = 'All';

  @override
  Widget build(BuildContext context) {
    ref.watch(ordersRealtimeProvider);
    ref.watch(activeOrdersProvider);
    final stateAsync = ref.watch(tableGridNotifierProvider);
    final activeOrders = ref.watch(ordersProjectionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      body: Row(
        children: [
          
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 40 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header & Zone Toggle
                        stateAsync.when(
                          loading: () => _buildPageHeader(isDark),
                          error: (_, _) => _buildPageHeader(isDark),
                          data: (state) {
                            // Extract unique floor names from tables
                            final floorNames = <String>{'All'};
                            for (final t in state.tables) {
                              if (t.floorName != null && t.floorName!.isNotEmpty) {
                                floorNames.add(t.floorName!);
                              }
                            }
                            final zones = floorNames.toList();
                            // Reset selection if current zone no longer exists
                            if (!zones.contains(_selectedZone)) {
                              _selectedZone = 'All';
                            }

                            if (isDesktop) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildPageHeader(isDark),
                                  _buildZoneTabs(isDark, zones),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPageHeader(isDark),
                                  const SizedBox(height: 16),
                                  _buildZoneTabs(isDark, zones),
                                ],
                              );
                            }
                          },
                        ),
                        
                        const SizedBox(height: 32),

                        // Main Grid
                        Consumer(
                          builder: (context, ref, child) {
                            final activeOrders = ref.watch(ordersProjectionProvider);
                            return stateAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(color: Color(0xFFE31E24)),
                                ),
                              ),
                              error: (err, stack) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFBA1A1A)),
                                    const SizedBox(height: 16),
                                    Text('Failed to load layout: $err', style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => ref.invalidate(tableGridNotifierProvider),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                              data: (state) {
                                // Filter tables by selected floor
                                final tables = _selectedZone == 'All'
                                    ? state.tables
                                    : state.tables.where((t) => t.floorName == _selectedZone).toList();

                                if (tables.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No tables available',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  );
                                }
                                
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = 1;
                                    double childAspectRatio = 3.2;

                                    if (constraints.maxWidth >= 900) {
                                      crossAxisCount = 3;
                                      childAspectRatio = 1.6;
                                    } else if (constraints.maxWidth >= 600) {
                                      crossAxisCount = 2;
                                      childAspectRatio = 1.8;
                                    }

                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: childAspectRatio,
                                      ),
                                      itemCount: tables.length,
                                      itemBuilder: (context, index) {
                                        final table = tables[index];
                                        return _buildTableCard(table, isDark, activeOrders)
                                          .animate()
                                          .fadeIn(delay: (50 * index).ms)
                                          .slideY(begin: 0.1, delay: (50 * index).ms);
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 48),
                        _buildStatusLegend(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Floor Layout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time table status.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? Colors.white54 : const Color(0xFF5D3F3C), // Using design's on-surface-variant equivalent
          ),
        ),
      ],
    );
  }

  Widget _buildZoneTabs(bool isDark, List<String> zones) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: zones.map((zone) {
            final isSelected = _selectedZone == zone;
            return InkWell(
              onTap: () => setState(() => _selectedZone = zone),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  zone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected 
                        ? const Color(0xFFE31E24)
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getTableAmount(RestaurantTable table, List<Order> activeOrders) {
    debugPrint('[TableGridScreen] _getTableAmount table=${table.label} activeOrdersCount=${activeOrders.length}');
    for (final o in activeOrders) {
      if (o.tableId == table.id) {
        debugPrint('  -> Order: num=${o.id} status=${o.status} price=${o.totalPrice.formatted}');
      }
    }
    var totalCents = 0;
    bool hasOrders = false;
    for (final o in activeOrders) {
      if (o.tableId == table.id && o.status != OrderStatus.completed && o.status != OrderStatus.cancelled && o.status != OrderStatus.delivered) {
        totalCents += o.totalPrice.amountInCents;
        hasOrders = true;
      }
    }
    return hasOrders ? Money(amountInCents: totalCents).formatted : '₹0.00';
  }

  Widget _buildTableCard(RestaurantTable table, bool isDark, List<Order> activeOrders) {
    final status = table.status;
    
    // Check if the table has any active order currently in the projection
    final hasActiveOrder = activeOrders.any((o) =>
        o.tableId == table.id &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled &&
        o.status != OrderStatus.delivered);

    // Map backend statuses to design states
    // Vacant = available (unless we have active orders, which means occupied)
    // Occupied = occupied
    // Calling = needsAttention
    // Bill Requested = reserved (mocked mapping)
    
    if (status == TableStatus.available && !hasActiveOrder) {
      return _buildVacantCard(table, isDark);
    } else if (status == TableStatus.needsAttention) {
      return _buildCallingCard(table, isDark, activeOrders);
    } else if (table.isPaymentRequested) {
      return _buildBillRequestedCard(table, isDark, activeOrders);
    } else if (status == TableStatus.reserved) {
      return _buildBillRequestedCard(table, isDark, activeOrders);
    } else {
      return _buildOccupiedCard(table, isDark, activeOrders);
    }
  }

  Widget _buildVacantCard(RestaurantTable table, bool isDark) {
    return InkWell(
      onTap: () => context.push('/tables/${table.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE1E3E4),
            style: BorderStyle.solid, // Using solid as dashed border is complex natively without packages
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    table.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF545C64),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFBFC8D0)),
                  ),
                  child: Text(
                    'Vacant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF545C64),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.add_circle_outline_rounded, size: 28, color: isDark ? Colors.white30 : const Color(0xFFBFC8D0)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupiedCard(RestaurantTable table, bool isDark, List<Order> activeOrders) {
    final amount = _getTableAmount(table, activeOrders);
    const time = '45m';
    
    return InkWell(
      onTap: () => context.push('/tables/${table.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    table.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E2E5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white54 : const Color(0xFF5D5E61))),
                      const SizedBox(width: 6),
                      Text(
                        'Occupied',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF636467),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE1E3E4))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_rounded, size: 16, color: isDark ? Colors.white54 : const Color(0xFF5D3F3C)),
                      const SizedBox(width: 4),
                      Text('${table.occupiedSeats.isNotEmpty ? table.occupiedSeats.length : table.capacity}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF5D3F3C))),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: isDark ? Colors.white54 : const Color(0xFF5D3F3C)),
                      const SizedBox(width: 4),
                      Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF5D3F3C))),
                    ],
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallingCard(RestaurantTable table, bool isDark, List<Order> activeOrders) {
    return InkWell(
      onTap: () => context.push('/tables/${table.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBA0013)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    table.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF93000A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA0013),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Calling',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 800.ms, begin: const Offset(1,1), end: const Offset(1.05, 1.05)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE7BDB8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 16, color: Color(0xFF93000A)),
                      const SizedBox(width: 4),
                      Text('${table.occupiedSeats.isNotEmpty ? table.occupiedSeats.length : table.capacity}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF93000A))),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF93000A)),
                      const SizedBox(width: 4),
                      Text('12m', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF93000A))),
                    ],
                  ),
                  Text(
                    _getTableAmount(table, activeOrders),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF93000A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRequestedCard(RestaurantTable table, bool isDark, List<Order> activeOrders) {
    return InkWell(
      onTap: () => context.push('/tables/${table.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDBE4ED),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    table.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF3F484F),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF545C64),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        table.isPaymentRequested ? '${table.customerPaymentIntent?.toUpperCase()} Req.' : 'Bill Req.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFBFC8D0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF3F484F)),
                      const SizedBox(width: 4),
                      Text('${table.occupiedSeats.isNotEmpty ? table.occupiedSeats.length : table.capacity}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF3F484F))),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF3F484F)),
                      const SizedBox(width: 4),
                      Text('90m', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF3F484F))),
                    ],
                  ),
                  Text(
                    _getTableAmount(table, activeOrders),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF3F484F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem('Vacant', isDark, isDashed: true, color: isDark ? Colors.white54 : const Color(0xFF545C64)),
          const SizedBox(width: 16),
          _buildLegendItem('Occupied', isDark, isDashed: false, color: isDark ? Colors.white30 : const Color(0xFFE2E2E5)),
          const SizedBox(width: 16),
          _buildLegendItem('Bill Requested', isDark, isDashed: false, color: isDark ? const Color(0xFF334155) : const Color(0xFFDBE4ED)),
          const SizedBox(width: 16),
          _buildLegendItem('Calling/Alert', isDark, isDashed: false, color: const Color(0xFFFFDAD6)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, bool isDark, {required bool isDashed, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF5D3F3C),
          ),
        ),
      ],
    );
  }
}
