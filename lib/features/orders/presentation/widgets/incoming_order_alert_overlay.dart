// lib/features/orders/presentation/widgets/incoming_order_alert_overlay.dart
//
// Premium "New Order" alert popup — Fullscreen overlay with:
//   • Real-time enrichment (items + total update as backend responds)
//   • Shimmer loading state while items are still being fetched
//   • Inline item list (no hidden toggle)
//   • Glassmorphism dark card with animated border pulse
//   • Stays on screen until a staff member accepts or passes (no auto-expire timer)

import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentAlert = ref.read(currentOrderAlertProvider);
      if (currentAlert != null && _currentOverlay == null) {
        _showAlertOverlay(currentAlert);
      }
      final currentReady = ref.read(currentReadyAlertProvider);
      if (currentReady != null && _currentReadyOverlay == null) {
        _showReadyOverlay(currentReady);
      }
    });
  }

  @override
  void dispose() {
    _dismissOverlay();
    _dismissReadyOverlay();
    super.dispose();
  }

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
      builder: (overlayContext) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _IncomingOrderAlertOverlay(
          orderId: alert.orderId,
          initialAlert: alert,
          onAccepted: () => _dismissOverlay(),
          onPassed: () => _dismissOverlay(),
          onExpired: () => _dismissOverlay(),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  void _dismissOverlay() {
    if (ref.read(pendingOrderAlertsProvider).isEmpty) {
      OrderAlertAudioManager().stopAlert();
    }
    _currentOverlay?.remove();
    _currentOverlay = null;
    _activeAlertId = null;
  }

  void _showReadyOverlay(OrderReadyAlert alert) {
    _activeReadyAlertId = alert.alertId;
    OrderAlertAudioManager().playOrderReadySound();
    HapticFeedback.heavyImpact();

    _currentReadyOverlay = OverlayEntry(
      builder: (overlayContext) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay Content — reads live state via orderId key so enrichment is reflected
// ─────────────────────────────────────────────────────────────────────────────

class _IncomingOrderAlertOverlay extends ConsumerStatefulWidget {
  /// We pass only the orderId (not the alert object) so the widget always
  /// reads the LATEST enriched alert from the live provider state.
  final String orderId;
  final IncomingOrderAlert initialAlert;
  final VoidCallback onAccepted;
  final VoidCallback onPassed;
  final VoidCallback onExpired;

  const _IncomingOrderAlertOverlay({
    required this.orderId,
    required this.initialAlert,
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

  // Tracks whether enrichment deadline has passed (shimmer → fallback message)
  bool _enrichmentDeadlinePassed = false;
  Timer? _enrichmentDeadlineTimer;

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

    // After 6s, if items are still empty, stop showing shimmer — show fallback message instead.
    // This covers the case where the backend is slow or enrichment fails all retries.
    _enrichmentDeadlineTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_enrichmentDeadlinePassed) {
        setState(() => _enrichmentDeadlinePassed = true);
      }
    });
  }

  @override
  void dispose() {
    _enrichmentDeadlineTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _onAccept(IncomingOrderAlert alert) async {
    if (_isAccepting) return;
    await HapticFeedback.heavyImpact();
    setState(() => _isAccepting = true);
    
    if (alert.intent == 'NEW_ORDER_FOR_MY_TABLE') {
      // Just dismiss the notification and optionally navigate. We don't assign.
      ref.read(orderAlertNotifierProvider.notifier).dismissAlert(alert.orderId);
      widget.onAccepted();
      if (alert.tableId != null && mounted) {
        unawaited(context.push('/tables/${alert.tableId}'));
      }


    } else {
      // TABLE_ASSIGNMENT_REQUIRED (or fallback): attempt to assign waiter
      final success = await ref
          .read(orderAlertNotifierProvider.notifier)
          .acceptAlert(alert.orderId, alert.versionNum);
      if (success) widget.onAccepted();
    }
    
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
    final liveAlert = alertState.queue.cast<IncomingOrderAlert?>().firstWhere(
      (a) => a?.orderId == widget.orderId || a?.alertId.startsWith(widget.orderId) == true,
      orElse: () => widget.initialAlert,
    ) ?? widget.initialAlert;

    // If this alert was removed from the queue (accepted/passed), dismiss
    if (!alertState.queue.any((a) => a.orderId == widget.orderId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAccepted(); // treat removal as accepted (already handled upstream)
      });
    }

    // isEnriched: true when we have either items OR a non-zero total
    final isEnriched = liveAlert.items.isNotEmpty ||
        (liveAlert.itemCount > 0 && liveAlert.totalAmountMinor > 0);
    // Once enriched, cancel the deadline timer
    if (isEnriched && _enrichmentDeadlineTimer?.isActive == true) {
      _enrichmentDeadlineTimer!.cancel();
    }

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



  Widget _buildCard(IncomingOrderAlert alert, bool isEnriched) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red header banner
            _buildHeaderBanner(alert),
            // Body content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _buildCardContent(alert, isEnriched),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(IncomingOrderAlert alert) {
    final isNewOrderForMe = alert.intent == 'NEW_ORDER_FOR_MY_TABLE';
    final bgColor = isNewOrderForMe ? const Color(0xFF1D4ED8) : const Color(0xFFE31E24);
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.rotate(
              angle: ((_pulseAnimation.value - 0.7) * 0.3),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isNewOrderForMe
                  ? 'New Order on Your Table'
                  : (alert.isReassignment ? 'Order Passed to You' : 'New Order Received!'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(IncomingOrderAlert alert, bool isEnriched) {
    final alertState = ref.watch(orderAlertNotifierProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overflow warning
        if (alertState.hasOverflow) ...[
          _buildOverflowBanner(alertState.overflowCount),
          const SizedBox(height: 12),
        ],

        // Table badge
        _buildTableBadge(alert),
        const SizedBox(height: 14),

        // Stats row: items / amount / time
        _buildStatsRow(alert, isEnriched),
        const SizedBox(height: 14),

        // Items list
        _buildItemsSection(alert, isEnriched),
        const SizedBox(height: 20),

        // Action buttons
        _buildActionButtons(alert),
      ],
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

  Widget _buildTableBadge(IncomingOrderAlert alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TABLE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE31E24),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                alert.tableNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ORDER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                alert.orderNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(IncomingOrderAlert alert, bool isEnriched) {
    final timeStr = TimeOfDay.fromDateTime(alert.orderTime).format(context);
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.shopping_bag_outlined,
          value: isEnriched ? '${alert.itemCount} items' : null,
          label: 'Items',
          color: const Color(0xFF0F172A),
          bgColor: const Color(0xFFF1F5F9),
          isLoading: !isEnriched,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.currency_rupee_rounded,
          value: isEnriched ? alert.formattedTotal : null,
          label: 'Total',
          color: const Color(0xFF0F172A),
          bgColor: const Color(0xFFF1F5F9),
          isLoading: !isEnriched,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.access_time_rounded,
          value: timeStr,
          label: 'Time',
          color: const Color(0xFF0F172A),
          bgColor: const Color(0xFFF1F5F9),
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
    Color? bgColor,
    required bool isLoading,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor ?? const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE31E24), size: 16),
            const SizedBox(height: 4),
            isLoading
                ? _buildShimmerLine(width: 32, height: 11, color: const Color(0xFF94A3B8))
                : Text(
                    value ?? '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
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
    if (!isEnriched || alert.items.isEmpty) {
      if (_enrichmentDeadlinePassed) return _buildItemsFallback();
      return _buildItemsShimmer();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFFE31E24), size: 14),
                const SizedBox(width: 6),
                Text(
                  'ORDER ITEMS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${alert.itemCount} items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFFE31E24),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),

          // Item rows
          ...alert.items.take(4).map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31E24).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE31E24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (alert.items.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '+${alert.items.length - 4} more items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          if (alert.items.length <= 4) const SizedBox(height: 6),
        ],
      ),
    );
  }



  Widget _buildItemsShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerLine(width: 100, height: 10, color: const Color(0xFFCBD5E1)),
              const Spacer(),
              _buildShimmerLine(width: 60, height: 10, color: const Color(0xFFCBD5E1)),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                _buildShimmerLine(width: 26, height: 26, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),
                _buildShimmerLine(width: 120 - i * 20.0, height: 12, color: const Color(0xFFCBD5E1)),
              ],
            ),
            if (i < 2) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  /// Shown after 6s if enrichment API never returns items — prevents infinite shimmer.
  Widget _buildItemsFallback() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Item details unavailable — please accept to view full order',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(IncomingOrderAlert alert) {
    final isNewOrderForMe = alert.intent == 'NEW_ORDER_FOR_MY_TABLE';

    return Column(
      children: [
        // Primary button: ACCEPT & CLAIM (green) or VIEW ORDER (blue)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : () => _onAccept(alert),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNewOrderForMe
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF16A34A),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isAccepting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNewOrderForMe ? Icons.visibility_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isNewOrderForMe ? 'VIEW ORDER' : 'ACCEPT & CLAIM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Pass button — only for unassigned tables
        if (!isNewOrderForMe) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _isPassing ? null : () => _onPass(alert),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Pass Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown ring painter
// ─────────────────────────────────────────────────────────────────────────────


