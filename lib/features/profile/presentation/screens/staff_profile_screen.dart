import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/state/auth_notifier.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final authState = ref.watch(authNotifierProvider);
    final staff = authState.loggedInStaff;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTextStyles.h3.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: staff == null && authState.selectedBranch == null
          ? const Center(child: CircularProgressIndicator())
          : staff == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_circle_outlined, size: 64, color: textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Staff Profile Unavailable',
                          style: AppTextStyles.h3.copyWith(color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load staff information. Please log in or refresh your shift.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).loadStaffForBranch();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Loading'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(staff, authState, surfaceColor, borderColor, textPrimary, textSecondary),
                    const SizedBox(height: 24),

                    _buildSectionHeader('PERSONAL INFORMATION', textSecondary),
                    _buildCard(
                      surfaceColor,
                      borderColor,
                      [
                        _buildRow('Full Name', textPrimary,
                            value: _getFullName(staff)),
                        _divider(borderColor),
                        _buildRow('Age', textPrimary, value: staff.age?.toString() ?? 'N/A'),
                        _divider(borderColor),
                        _buildRow('Gender', textPrimary, value: staff.gender ?? 'N/A'),
                        _divider(borderColor),
                        _buildRow('DOB', textPrimary,
                            value: staff.dob != null ? staff.dob!.toIso8601String().split('T').first : 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('CONTACT INFORMATION', textSecondary),
                    _buildCard(
                      surfaceColor,
                      borderColor,
                      [
                        _buildRow('Mobile Number', textPrimary, value: _formatValue(staff.mobileNumber)),
                        _divider(borderColor),
                        _buildRow('Email', textPrimary, value: _formatValue(staff.email)),
                        _divider(borderColor),
                        _buildRow('Address', textPrimary, value: _formatValue(staff.address)),
                        _divider(borderColor),
                        _buildRow('Emergency Contact', textPrimary, value: _formatValue(staff.emergencyContactName ?? staff.emergencyContact)),
                        _divider(borderColor),
                        _buildRow('Emergency Number', textPrimary, value: _formatValue(staff.emergencyContactNumber)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('EMPLOYMENT INFORMATION', textSecondary),
                    _buildCard(
                      surfaceColor,
                      borderColor,
                      [
                        _buildRow('Employee ID', textPrimary, value: _formatValue(staff.employeeId)),
                        _divider(borderColor),
                        _buildRow('Role', textPrimary, value: _formatRole(staff.role)),
                        _divider(borderColor),
                        _buildRow('Restaurant', textPrimary, value: authState.selectedOrg?.name ?? 'Orderlyy'),
                        _divider(borderColor),
                        _buildRow('Branch', textPrimary, value: staff.branch ?? authState.selectedBranch?.name ?? 'N/A'),
                        if (staff.section != null && staff.section!.isNotEmpty) ...[
                          _divider(borderColor),
                          _buildRow('Assigned Section', textPrimary, value: staff.section!),
                        ],
                        _divider(borderColor),
                        _buildRow('Department', textPrimary, value: _formatValue(staff.department)),
                        _divider(borderColor),
                        _buildRow('Joining Date', textPrimary,
                            value: staff.joiningDate != null
                                ? '${staff.joiningDate!.year}-${staff.joiningDate!.month.toString().padLeft(2, '0')}-${staff.joiningDate!.day.toString().padLeft(2, '0')}'
                                : 'N/A'),
                        _divider(borderColor),
                        _buildRow('Status', textPrimary,
                            value: staff.employmentStatus ?? 'Active', valueColor: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(Color surfaceColor, Color borderColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(String label, Color textPrimary, {String? value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (value != null)
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(Color color) => Divider(height: 1, indent: 16, color: color);

  Widget _buildHeaderCard(
    dynamic staff,
    dynamic authState,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final fullName = _getFullName(staff);
    final roleStr = _formatRole(staff.role);
    final branchStr = staff.branch ?? authState.selectedBranch?.name ?? 'Main Branch';
    final orgStr = authState.selectedOrg?.name ?? 'Orderlyy';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: staff.profilePhoto != null && staff.profilePhoto!.isNotEmpty
                ? NetworkImage(staff.profilePhoto!)
                : null,
            child: staff.profilePhoto == null || staff.profilePhoto!.isEmpty
                ? Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppTextStyles.h3.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$roleStr • $branchStr',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  orgStr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFullName(dynamic staff) {
    final firstLast = '${staff.firstName} ${staff.lastName}'.trim();
    if (firstLast.isNotEmpty) return firstLast;
    if (staff.name != null && staff.name.isNotEmpty) return staff.name;
    return 'Staff Member';
  }

  String _formatValue(String? val) {
    if (val == null || val.trim().isEmpty) return 'N/A';
    return val;
  }

  String _formatRole(dynamic role) {
    if (role == null) return 'Staff';
    final roleName = role.name.toString();
    switch (roleName.toLowerCase()) {
      case 'waiter':
        return 'Waiter / Server';
      case 'runner':
        return 'Food Runner';
      case 'host':
        return 'Host / Greeter';
      case 'kdsoperator':
      case 'kds_operator':
        return 'KDS Operator';
      case 'manager':
        return 'Restaurant Manager';
      default:
        return roleName[0].toUpperCase() + roleName.substring(1);
    }
  }
}
