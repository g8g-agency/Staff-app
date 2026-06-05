import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: staff == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('PERSONAL INFORMATION', textSecondary),
                _buildCard(
                  surfaceColor,
                  borderColor,
                  [
                    _buildRow('Full Name', textPrimary, value: '${staff.firstName} ${staff.lastName}'.trim()),
                    _divider(borderColor),
                    _buildRow('Age', textPrimary, value: staff.age?.toString() ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Gender', textPrimary, value: staff.gender ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('DOB', textPrimary, value: staff.dob != null ? staff.dob!.toIso8601String().split('T').first : 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader('CONTACT INFORMATION', textSecondary),
                _buildCard(
                  surfaceColor,
                  borderColor,
                  [
                    _buildRow('Mobile Number', textPrimary, value: staff.mobileNumber ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Email', textPrimary, value: staff.email ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Address', textPrimary, value: staff.address ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Emergency Contact', textPrimary, value: staff.emergencyContactName ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Emergency Number', textPrimary, value: staff.emergencyContactNumber ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader('EMPLOYMENT INFORMATION', textSecondary),
                _buildCard(
                  surfaceColor,
                  borderColor,
                  [
                    _buildRow('Employee ID', textPrimary, value: staff.employeeId ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Role', textPrimary, value: staff.role.name.toUpperCase()),
                    _divider(borderColor),
                    _buildRow('Branch', textPrimary, value: staff.branch ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Department', textPrimary, value: staff.department ?? 'N/A'),
                    _divider(borderColor),
                    _buildRow('Joining Date', textPrimary, value: staff.joiningDate != null ? '${staff.joiningDate!.year}-${staff.joiningDate!.month}-${staff.joiningDate!.day}' : 'N/A'),
                    _divider(borderColor),
                    _buildRow('Status', textPrimary, value: staff.employmentStatus ?? 'Active', valueColor: AppColors.success),
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
}
