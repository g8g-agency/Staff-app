import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/state/auth_notifier.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedGender = 'Prefer Not To Say';
  
  // Step 2 Controllers
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyNumberController = TextEditingController();

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer Not To Say'];

  @override
  void initState() {
    super.initState();
    final staff = ref.read(authNotifierProvider).loggedInStaff;
    final initialStep = (staff?.profileSetupStep ?? 1) - 1;
    _currentStep = initialStep < 0 ? 0 : (initialStep > 1 ? 1 : initialStep);
    
    _pageController = PageController(initialPage: _currentStep);

    if (staff != null) {
      _firstNameController.text = staff.firstName;
      _lastNameController.text = staff.lastName;
      _selectedGender = staff.gender ?? 'Prefer Not To Say';
      _mobileController.text = staff.mobileNumber ?? '';
      _addressController.text = staff.address ?? '';
      _emergencyNameController.text = staff.emergencyContactName ?? '';
      _emergencyNumberController.text = staff.emergencyContactNumber ?? '';
      if (staff.dob != null) {
        _dobController.text = staff.dob!.toIso8601String().split('T').first;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveStep(int step) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    final data = <String, dynamic>{
      'profile_setup_step': step + 1,
    };

    if (step == 1) { // Saving step 1 (0-indexed) -> moving to step 2
      data['first_name'] = _firstNameController.text.trim();
      data['last_name'] = _lastNameController.text.trim();
      data['gender'] = _selectedGender;
      if (_dobController.text.isNotEmpty) {
        data['date_of_birth'] = _dobController.text.trim();
      }
    } else if (step == 2) { // Completing step 2
      data['mobile_number'] = _mobileController.text.trim();
      data['address'] = _addressController.text.trim();
      data['emergency_contact_name'] = _emergencyNameController.text.trim();
      data['emergency_contact_number'] = _emergencyNumberController.text.trim();
      data['profile_completed'] = true;
    }

    final success = await authNotifier.updateProfile(data);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = 'Failed to save profile. Please try again.';
        }
      });

      if (success) {
        if (step == 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => _currentStep = 1);
        } else {
          // Go router will automatically redirect to dashboard since profile_completed is now true!
          // But just in case, we can force a refresh or redirect.
        }
      }
    }
  }

  void _validateAndProceedStep1() {
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty || 
        _dobController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields (*)');
      return;
    }
    _saveStep(1);
  }

  void _validateAndCompleteStep2() {
    if (_mobileController.text.trim().isEmpty || 
        _addressController.text.trim().isEmpty || 
        _emergencyNameController.text.trim().isEmpty || 
        _emergencyNumberController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields (*)');
      return;
    }
    _saveStep(2);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // Default age ~20
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
            ),
            dialogBackgroundColor: AppColors.darkSurface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(AppSpacing.xl(context)),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete Your Profile',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm(context)),
              Text(
                _currentStep == 0 
                  ? 'Step 1: Let\'s set up your personal information.' 
                  : 'Step 2: Contact & Employment Information.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl(context)),
              
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(AppSpacing.md(context)),
                  margin: EdgeInsets.only(bottom: AppSpacing.lg(context)),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      SizedBox(width: AppSpacing.sm(context)),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(context, isDark, textPrimary, textSecondary, borderColor),
                    _buildStep2(context, isDark, textPrimary, textSecondary, borderColor),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xl(context)),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                      onPressed: _currentStep == 0 ? _validateAndProceedStep1 : _validateAndCompleteStep2,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentStep == 0 ? 'Next Step' : 'Complete Setup',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, Color textPrimary, Color textSecondary, Color borderColor, {bool required = false, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (required)
                  TextSpan(text: ' *', style: GoogleFonts.inter(color: AppColors.error)),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xs(context)),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.inter(color: textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : AppColors.lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md(context), vertical: AppSpacing.sm(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(context, 'First Name', _firstNameController, textPrimary, textSecondary, borderColor, required: true)),
              SizedBox(width: AppSpacing.md(context)),
              Expanded(child: _buildTextField(context, 'Last Name', _lastNameController, textPrimary, textSecondary, borderColor, required: true)),
            ],
          ),
          _buildTextField(context, 'Date of Birth (YYYY-MM-DD)', _dobController, textPrimary, textSecondary, borderColor, required: true, readOnly: true, onTap: () => _selectDate(context)),
          
          Text(
            'Gender *',
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.xs(context)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md(context)),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                isExpanded: true,
                dropdownColor: surfaceColor,
                style: GoogleFonts.inter(color: textPrimary),
                items: _genderOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedGender = newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    final staff = ref.read(authNotifierProvider).loggedInStaff;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(context, 'Mobile Number', _mobileController, textPrimary, textSecondary, borderColor, required: true),
          _buildTextField(context, 'Address', _addressController, textPrimary, textSecondary, borderColor, required: true),
          Row(
            children: [
              Expanded(child: _buildTextField(context, 'Emergency Contact Name', _emergencyNameController, textPrimary, textSecondary, borderColor, required: true)),
              SizedBox(width: AppSpacing.md(context)),
              Expanded(child: _buildTextField(context, 'Emergency Contact Number', _emergencyNumberController, textPrimary, textSecondary, borderColor, required: true)),
            ],
          ),
          
          SizedBox(height: AppSpacing.md(context)),
          Text(
            'Employment Information (Auto-filled)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md(context)),
          
          Container(
            padding: EdgeInsets.all(AppSpacing.md(context)),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Employee ID', staff?.employeeId ?? 'N/A', textPrimary, textSecondary),
                SizedBox(height: AppSpacing.sm(context)),
                _buildInfoRow('Role', staff?.role.name.toUpperCase() ?? 'N/A', textPrimary, textSecondary),
                SizedBox(height: AppSpacing.sm(context)),
                _buildInfoRow('Branch', staff?.branch ?? 'Current Branch', textPrimary, textSecondary),
                SizedBox(height: AppSpacing.sm(context)),
                _buildInfoRow('Department', staff?.department ?? 'General', textPrimary, textSecondary),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
