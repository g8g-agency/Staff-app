// lib/features/orders/presentation/widgets/incoming_order_alert_overlay.dart
//
// Fullscreen Rapido/Uber-style order alert popup.
// Appears over any screen. Animated entrance. 30s countdown.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/order_alert_model.dart';
import '../state/order_alert_notifier.dart';
import '../services/order_alert_audio_manager.dart';
import 'pass_order_bottom_sheet.dart';
import 'order_ready_popup.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    // Keep real-time orders connection alive globally while the shell is mounted
    ref.watch(ordersRealtimeProvider);

    ref.listen<IncomingOrderAlert?>(currentOrderAlertProvider, (prev, next) {
      if (next == null) {
        _dismissOverlay();
        return;
      }
      // Only show if it's a different alert than what's currently displayed
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

    // Start audio
    OrderAlertAudioManager().startAlert();

    _currentOverlay = OverlayEntry(
      builder: (context) => _IncomingOrderAlertOverlay(
        alert: alert,
        onAccepted: () => _dismissOverlay(),
        onPassed: () => _dismissOverlay(),
        onExpired: () => _dismissOverlay(),
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

  // --- Ready Alert Overlay Logic ---
  OverlayEntry? _currentReadyOverlay;
  String? _activeReadyAlertId;

  void _showReadyOverlay(OrderReadyAlert alert) {
    _activeReadyAlertId = alert.alertId;

    // Start distinct audio & vibration
    OrderAlertAudioManager().playOrderReadySound();
    HapticFeedback.heavyImpact();

    _currentReadyOverlay = OverlayEntry(
      builder: (context) => OrderReadyPopupOverlay(
        alert: alert,
        onAcknowledge: () {
          ref
              .read(orderAlertNotifierProvider.notifier)
              .dismissReadyAlert(alert.orderId);
          _dismissReadyOverlay();
        },
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
// Overlay Content
// ─────────────────────────────────────────────────────────────────────────────

class _IncomingOrderAlertOverlay extends ConsumerStatefulWidget {
  final IncomingOrderAlert alert;
  final VoidCallback onAccepted;
  final VoidCallback onPassed;
  final VoidCallback onExpired;

  const _IncomingOrderAlertOverlay({
    required this.alert,
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
  late AnimationController _countdownController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _itemsExpanded = false;
  bool _isAccepting = false;
  bool _isPassing = false;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutBack,
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    // Pulse animation for the card border
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Countdown controller kept but not used for auto-expiry
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _onExpired() {
    ref
        .read(orderAlertNotifierProvider.notifier)
        .expireAlert(widget.alert.orderId);
    widget.onExpired();
  }

  Future<void> _onAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    final success = await ref
        .read(orderAlertNotifierProvider.notifier)
        .acceptAlert(widget.alert.orderId, widget.alert.versionNum);
    if (success) widget.onAccepted();
    if (mounted) setState(() => _isAccepting = false);
  }

  Future<void> _onPass() async {
    if (_isPassing) return;
    setState(() => _isPassing = true);
    final staffId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassOrderBottomSheet(alert: widget.alert),
    );
    if (mounted) setState(() => _isPassing = false);
    if (staffId != null) widget.onPassed();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(color: Colors.black.withValues(alpha: 0.75)),
          ),

          // Alert card
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxWidth: 420),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(
                  0xFFFF6B35,
                ).withValues(alpha: _pulseAnimation.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6B35,
                  ).withValues(alpha: 0.3 * _pulseAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    final alertState = ref.watch(orderAlertNotifierProvider);
    // Find the current live version of this alert from the state to catch updates/enrichment
    final liveAlert = alertState.queue.firstWhere(
      (a) => a.orderId == widget.alert.orderId,
      orElse: () => widget.alert,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alertState.hasOverflow)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ ${alertState.overflowCount} alert(s) dropped — queue was full',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(orderAlertNotifierProvider.notifier).clearOverflow();
                    },
                  ),
                ],
              ),
            ),
          _buildHeader(liveAlert),
          const SizedBox(height: 20),
          _buildTableBadge(liveAlert),
          const SizedBox(height: 20),
          _buildOrderDetails(liveAlert),
          const SizedBox(height: 12),
          _buildItemsList(liveAlert),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(IncomingOrderAlert alert) {
    return Row(
      children: [
        // Bell icon with pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(
                  0xFFFF6B35,
                ).withValues(alpha: _pulseAnimation.value),
              ),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Color(0xFFFF6B35),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.isReassignment
                    ? 'Order Passed to You'
                    : 'New Order Received!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.2),
            const Color(0xFFFF8C42).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TABLE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.tableNumber,
            style: GoogleFonts.inter(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF6B35),
              height: 1,
            ),
          ),
          Text(
            alert.orderNumber,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(IncomingOrderAlert alert) {
    final timeStr = TimeOfDay.fromDateTime(
      alert.orderTime,
    ).format(context);
    return Row(
      children: [
        _buildDetailChip(
          Icons.shopping_bag_outlined,
          '${alert.itemCount} Items',
          const Color(0xFF4ECDC4),
        ),
        const SizedBox(width: 8),
        _buildDetailChip(
          Icons.currency_rupee,
          alert.formattedTotal.replaceAll('₹', ''),
          const Color(0xFFFFD700),
        ),
        const SizedBox(width: 8),
        _buildDetailChip(Icons.access_time, timeStr, Colors.white54),
      ],
    );
  }


  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(IncomingOrderAlert alert) {
    if (alert.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _itemsExpanded ? 'Hide Items' : 'View Items',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _itemsExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF4ECDC4),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _itemsExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: alert.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4ECDC4,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '×${item.quantity}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF4ECDC4),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }




  Widget _buildActionButtons() {
    return Column(
      children: [
        // Accept button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : _onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C851), Color(0xFF007E33)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C851).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Accept Order',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        // Pass button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isPassing ? null : _onPass,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: Colors.white70,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swap_horiz, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pass Order',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
    final radius = (size.width / 2) - 3;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
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
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.progress != progress || old.color != color;
}
