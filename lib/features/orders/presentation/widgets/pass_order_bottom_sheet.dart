// lib/features/orders/presentation/widgets/pass_order_bottom_sheet.dart
//
// Bottom sheet showing available staff members to pass an order to.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/entities/order_alert_model.dart';
import '../state/order_alert_notifier.dart';
import '../../../../features/auth/presentation/state/auth_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Available staff provider (fetches from backend)
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableStaffMember {
  final String id;
  final String name;
  final String role;
  final int activeOrderCount;

  const _AvailableStaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.activeOrderCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────

class PassOrderBottomSheet extends ConsumerStatefulWidget {
  final IncomingOrderAlert alert;

  const PassOrderBottomSheet({super.key, required this.alert});

  @override
  ConsumerState<PassOrderBottomSheet> createState() => _PassOrderBottomSheetState();
}

class _PassOrderBottomSheetState extends ConsumerState<PassOrderBottomSheet> {
  List<_AvailableStaffMember> _staffList = [];
  bool _isLoading = true;
  String? _error;
  String? _passingToId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final dio = ref.read(dioClientProvider);
      final authState = ref.read(authNotifierProvider);
      final branchId = authState.selectedBranch?.id;
      final currentUserId = authState.loggedInStaff?.id;

      if (branchId == null) {
        setState(() {
          _error = 'No branch selected.';
          _isLoading = false;
        });
        return;
      }

      final response = await dio.get(
        '/api/v1/orders/alerts/staff-available',
        queryParameters: {'branchId': branchId},
      );

      if (response.statusCode == 200) {
        final list = (response.data['data']['staff'] as List<dynamic>? ?? [])
            .map((s) => _AvailableStaffMember(
                  id: s['id'] as String,
                  name: s['name'] as String,
                  role: (s['role'] as String).toLowerCase(),
                  activeOrderCount: (s['activeOrderCount'] as int?) ?? 0,
                ))
            .where((s) => s.id != currentUserId) // exclude self
            .toList()
          ..sort((a, b) => a.activeOrderCount.compareTo(b.activeOrderCount));

        setState(() {
          _staffList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load available staff.';
        _isLoading = false;
      });
    }
  }

  Future<void> _passTo(_AvailableStaffMember staff) async {
    setState(() => _passingToId = staff.id);

    final authState = ref.read(authNotifierProvider);
    final branchId = authState.selectedBranch?.id ?? '';

    final success = await ref.read(orderAlertNotifierProvider.notifier).passAlert(
          orderId: widget.alert.orderId,
          toStaffId: staff.id,
          branchId: branchId,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(staff.id); // return staff id as signal
      } else {
        setState(() => _passingToId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pass order. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFF4ECDC4)),
                const SizedBox(width: 10),
                Text(
                  'Pass Order — Table ${widget.alert.tableNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select an available staff member to handle this order.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
          ),

          const SizedBox(height: 16),

          // Staff list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: GoogleFonts.inter(color: Colors.red.shade300),
              ),
            )
          else if (_staffList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.group_off, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No available staff found.',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                itemCount: _staffList.length,
                itemBuilder: (_, i) => _buildStaffTile(_staffList[i]),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStaffTile(_AvailableStaffMember staff) {
    final isPassing = _passingToId == staff.id;
    final orderCountColor = staff.activeOrderCount == 0
        ? const Color(0xFF00C851)
        : staff.activeOrderCount <= 2
            ? const Color(0xFFFFD700)
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: isPassing ? null : () => _passTo(staff),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4ECDC4).withOpacity(0.15),
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              color: const Color(0xFF4ECDC4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          staff.name,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          staff.role.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        trailing: isPassing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4ECDC4),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: orderCountColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${staff.activeOrderCount} active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: orderCountColor,
                  ),
                ),
              ),
      ),
    );
  }
}
