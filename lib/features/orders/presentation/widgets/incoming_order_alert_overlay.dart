// lib/features/orders/presentation/widgets/incoming_order_alert_overlay.dart
//
// Premium "New Order" alert popup — Fullscreen overlay with:
//   • Real-time enrichment (items + total update as backend responds)
//   • Shimmer loading state while items are still being fetched
//   • Inline item list (no hidden toggle)
//   • Glassmorphism dark card with animated border pulse
//   • Stays on screen until a staff member accepts or passes (no auto-expire timer)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/order_alert_model.dart';
import '../state/order_alert_notifier.dart';
import '../services/order_alert_audio_manager.dart';
import 'pass_order_bottom_sheet.dart';
import 'order_ready_popup.dart';
import '../../providers/orders_realtime_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root listener widget — attach inside ShellRoute builder
// ─────────────────────────────────────────────────────────────────────────────

class OrderAlertListener extends ConsumerStatefulWidget {
  final Widget child;
  const OrderAlertListener({super.key, required this.child});

  @override
  ConsumerState<OrderAlertListener> createState() => _OrderAlertListenerState();
}

class _OrderAlertListenerState extends ConsumerState<OrderAlertListener> {
  OverlayEntry? _currentOverlay;
  String? _activeAlertId;
  OverlayEntry? _currentReadyOverlay;
  String? _activeReadyAlertId;

  @override
  Widget build(BuildContext context) {
    // Keep real-time orders connection alive globally while the shell is mounted
    ref.watch(ordersRealtimeProvider);

    ref.listen<IncomingOrderAlert?>(currentOrderAlertProvider, (prev, next) {
      if (next == null) {
        _dismissOverlay();
        return;
      }
      if (next.orderId == _activeAlertId) return;

      _dismissOverlay();
      _showAlertOverlay(next);
    });

    ref.listen<OrderReadyAlert?>(currentReadyAlertProvider, (prev, next) {
      if (next == null) {
        _dismissReadyOverlay();
        return;
      }
      if (next.alertId == _activeReadyAlertId) return;

      _dismissReadyOverlay();
      _showReadyOverlay(next);
    });

    return widget.child;
  }

  void _showAlertOverlay(IncomingOrderAlert alert) {
    _activeAlertId = alert.orderId;
    OrderAlertAudioManager().startAlert();

    // CRITICAL FIX: Wrap the overlay in ProviderScope so it has access to Riverpod
    // and can reactively update when enrichAlert() is called with real items/total.
    _currentOverlay = OverlayEntry(
      builder: (overlayContext) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _IncomingOrderAlertOverlay(
          orderId: alert.orderId,
          onAccepted: () => _dismissOverlay(),
          onPassed: () => _dismissOverlay(),
          onExpired: () => _dismissOverlay(),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  void _dismissOverlay() {
    OrderAlertAudioManager().stopAlert();
    _currentOverlay?.remove();
    _currentOverlay = null;
    _activeAlertId = null;
  }

  void _showReadyOverlay(OrderReadyAlert alert) {
    _activeReadyAlertId = alert.alertId;
    OrderAlertAudioManager().playOrderReadySound();
    HapticFeedback.heavyImpact();

    _currentReadyOverlay = OverlayEntry(
      builder: (overlayContext) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: OrderReadyPopupOverlay(
          alert: alert,
          onAcknowledge: () {
            ref
                .read(orderAlertNotifierProvider.notifier)
                .dismissReadyAlert(alert.orderId);
            _dismissReadyOverlay();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentReadyOverlay!);
  }

  void _dismissReadyOverlay() {
    _currentReadyOverlay?.remove();
    _currentReadyOverlay = null;
    _activeReadyAlertId = null;
  }

  @override
  void dispose() {
    _dismissOverlay();
    _dismissReadyOverlay();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay Content — reads live state via orderId key so enrichment is reflected
// ─────────────────────────────────────────────────────────────────────────────

class _IncomingOrderAlertOverlay extends ConsumerStatefulWidget {
  /// We pass only the orderId (not the alert object) so the widget always
  /// reads the LATEST enriched alert from the live provider state.
  final String orderId;
  final VoidCallback onAccepted;
  final VoidCallback onPassed;
  final VoidCallback onExpired;

  const _IncomingOrderAlertOverlay({
    required this.orderId,
    required this.onAccepted,
    required this.onPassed,
    required this.onExpired,
  });

  @override
  ConsumerState<_IncomingOrderAlertOverlay> createState() =>
      _IncomingOrderAlertOverlayState();
}

class _IncomingOrderAlertOverlayState
    extends ConsumerState<_IncomingOrderAlertOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isAccepting = false;
  bool _isPassing = false;

  // Shimmer animation for loading state
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance: slide up from bottom + scale
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0, 0.6)),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // Pulse for border glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 30s countdown removed — popup stays until staff accepts or passes

    // Shimmer for loading state
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onExpired() {
    ref.read(orderAlertNotifierProvider.notifier).expireAlert(widget.orderId);
    widget.onExpired();
  }

  Future<void> _onAccept(IncomingOrderAlert alert) async {
    if (_isAccepting) return;
    HapticFeedback.heavyImpact();
    setState(() => _isAccepting = true);
    final success = await ref
        .read(orderAlertNotifierProvider.notifier)
        .acceptAlert(alert.orderId, alert.versionNum);
    if (success) widget.onAccepted();
    if (mounted) setState(() => _isAccepting = false);
  }

  Future<void> _onPass(IncomingOrderAlert alert) async {
    if (_isPassing) return;
    setState(() => _isPassing = true);
    final staffId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassOrderBottomSheet(alert: alert),
    );
    if (mounted) setState(() => _isPassing = false);
    if (staffId != null) widget.onPassed();
  }

  @override
  Widget build(BuildContext context) {
    // Always read the LATEST live version of this alert — this is what enables
    // enrichment to appear (items/total update from 0 to real values).
    final alertState = ref.watch(orderAlertNotifierProvider);
    final liveAlert = alertState.queue.firstWhere(
      (a) => a.orderId == widget.orderId,
      orElse: () => alertState.queue.firstOrNull ?? _emptyAlert(),
    );

    // If this alert was removed from the queue (accepted/passed), dismiss
    if (!alertState.queue.any((a) => a.orderId == widget.orderId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAccepted(); // treat removal as accepted (already handled upstream)
      });
    }

    final isEnriched = liveAlert.itemCount > 0 || liveAlert.items.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred dark backdrop
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black.withValues(alpha: 0.78),
            ),
          ),

          // Alert card
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCard(liveAlert, isEnriched),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IncomingOrderAlert _emptyAlert() => IncomingOrderAlert(
        alertId: 'empty',
        orderId: widget.orderId,
        orderNumber: 'N/A',
        tableNumber: 'N/A',
        itemCount: 0,
        totalAmountMinor: 0,
        versionNum: 1,
        orderTime: DateTime.now(),
        receivedAt: DateTime.now(),
        items: const [],
      );

  Widget _buildCard(IncomingOrderAlert alert, bool isEnriched) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxWidth: 420),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1C2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFF6B35).withValues(alpha: _pulseAnimation.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.35 * _pulseAnimation.value),
                blurRadius: 50,
                spreadRadius: 8,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
        child: _buildCardContent(alert, isEnriched),
      ),
    );
  }

  Widget _buildCardContent(IncomingOrderAlert alert, bool isEnriched) {
    final alertState = ref.watch(orderAlertNotifierProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overflow warning
          if (alertState.hasOverflow) ...[
            _buildOverflowBanner(alertState.overflowCount),
            const SizedBox(height: 12),
          ],

          // Header row: bell icon + title
          _buildHeader(alert),
          const SizedBox(height: 16),

          // Table badge
          _buildTableBadge(alert),
          const SizedBox(height: 16),

          // Stats row: items / amount / time
          _buildStatsRow(alert, isEnriched),
          const SizedBox(height: 14),

          // Items list — always visible, shows shimmer while loading
          _buildItemsSection(alert, isEnriched),
          const SizedBox(height: 20),

          // Action buttons
          _buildActionButtons(alert),
        ],
      ),
    );
  }

  Widget _buildOverflowBanner(int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count alert(s) dropped — queue was full',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(orderAlertNotifierProvider.notifier).clearOverflow(),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(IncomingOrderAlert alert) {
    return Row(
      children: [
        // Animated bell
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: _pulseAnimation.value),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFF6B35),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.isReassignment ? 'Order Passed to You' : 'New Order Received!',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Accept or pass the order below',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableBadge(IncomingOrderAlert alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.18),
            const Color(0xFFFF8C42).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TABLE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            alert.tableNumber,
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF6B35),
              height: 1.1,
            ),
          ),
          Text(
            alert.orderNumber,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(IncomingOrderAlert alert, bool isEnriched) {
    final timeStr = TimeOfDay.fromDateTime(alert.orderTime).format(context);

    return Row(
      children: [
        // Items chip
        _buildStatChip(
          icon: Icons.shopping_bag_outlined,
          value: isEnriched ? '${alert.itemCount}' : null,
          label: 'Items',
          color: const Color(0xFF4ECDC4),
          isLoading: !isEnriched,
        ),
        const SizedBox(width: 8),

        // Amount chip
        _buildStatChip(
          icon: Icons.currency_rupee_rounded,
          value: isEnriched ? alert.formattedTotal.replaceAll('₹', '') : null,
          label: '₹ Total',
          color: const Color(0xFFFFD700),
          isLoading: !isEnriched,
        ),
        const SizedBox(width: 8),

        // Time chip (always available)
        _buildStatChip(
          icon: Icons.access_time_rounded,
          value: timeStr,
          label: 'Time',
          color: Colors.white54,
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String? value,
    required String label,
    required Color color,
    required bool isLoading,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 5),
            isLoading
                ? _buildShimmerLine(width: 32, height: 12, color: color)
                : Text(
                    value ?? '—',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLine({required double width, required double height, required Color color}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  color.withValues(alpha: 0.08),
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
                stops: [
                  (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
                  (_shimmerAnimation.value).clamp(0.0, 1.0),
                  (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsSection(IncomingOrderAlert alert, bool isEnriched) {
    if (!isEnriched) {
      // Show shimmer skeleton rows while waiting for enrichment
      return _buildItemsShimmer();
    }

    if (alert.items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFF4ECDC4), size: 14),
                const SizedBox(width: 6),
                Text(
                  'ORDER ITEMS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${alert.itemCount} items',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF4ECDC4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Item rows (max 4 visible to keep card compact)
          ...alert.items.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Row(
                    children: [
                      // Qty badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ×qty text
                      Text(
                        '×${item.quantity}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          // "... more" indicator
          if (alert.items.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '+${alert.items.length - 4} more items',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white30,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          if (alert.items.length <= 4) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItemsShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerLine(width: 100, height: 10, color: const Color(0xFF4ECDC4)),
              const Spacer(),
              _buildShimmerLine(width: 60, height: 10, color: const Color(0xFF4ECDC4)),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                _buildShimmerLine(width: 26, height: 26, color: const Color(0xFFFF6B35)),
                const SizedBox(width: 10),
                _buildShimmerLine(width: 120 - i * 20.0, height: 12, color: Colors.white),
                const Spacer(),
                _buildShimmerLine(width: 24, height: 12, color: Colors.white30),
              ],
            ),
            if (i < 2) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(IncomingOrderAlert alert) {
    return Column(
      children: [
        // Accept
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : () => _onAccept(alert),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              disabledBackgroundColor: Colors.transparent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isAccepting
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isAccepting
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Accept Order',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Pass
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isPassing ? null : () => _onPass(alert),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: Colors.white54,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swap_horiz_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pass Order',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CountdownRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.progress != progress || old.color != color;
}
