import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/auth_notifier.dart';

class ShiftStartScreen extends ConsumerStatefulWidget {
  const ShiftStartScreen({super.key});

  @override
  ConsumerState<ShiftStartScreen> createState() => _ShiftStartScreenState();
}

class _ShiftStartScreenState extends ConsumerState<ShiftStartScreen> {
  String _selectedSection = 'Main Hall';

  final List<String> _zones = ['Main Hall', 'Patio', 'Bar'];

  @override
  void dispose() {
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    const isDark = false; // Forced light mode

    final staff = authState.loggedInStaff;
    if (staff == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE31E24).withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFFE31E24),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              authState.selectedOrg?.name ?? 'Orderlyy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF0F172A),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 40.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    '${_getGreeting()}, ${staff.name.split(' ').first}.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isDesktop ? 32 : 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE31E24), // Orderlyy Red
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for a great shift? Let\'s get set up.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Content Grid
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildShiftSetupCard(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }

  Widget _buildShiftSetupCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shift Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),

          // Zone Selection
          Text(
            'ASSIGNED ZONE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _zones.map((zone) {
              final isSelected = _selectedSection == zone;
              IconData icon;
              if (zone == 'Main Hall') {
                icon = Icons.storefront_rounded;
              } else if (zone == 'Patio') {
                icon = Icons.deck_rounded;
              } else {
                icon = Icons.local_bar_rounded;
              }

              return InkWell(
                onTap: () => setState(() => _selectedSection = zone),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE31E24).withValues(alpha: 0.1)
                        : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8F9FA)),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE31E24)
                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? const Color(0xFFE31E24)
                            : (isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFE31E24)
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // Clock In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final currentStaff = ref
                    .read(authNotifierProvider)
                    .loggedInStaff;
                if (currentStaff != null) {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .startShift(currentStaff.role, _selectedSection);
                  if (mounted) {
                    final error = ref.read(authNotifierProvider).errorMessage;
                    if (ref.read(authNotifierProvider).isShiftStarted) {
                      context.go('/tables');
                    } else if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Clock In Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
