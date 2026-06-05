// lib/features/auth/domain/entities/staff_member.dart

enum StaffRole { waiter, runner, host, kdsOperator, manager }

class StaffMember {
  final String id;
  final String? employeeId;
  final String name;
  final String pin;
  final StaffRole role;
  final String? section;
  final bool developerModeEnabled;
  final String? department;
  final int? age;
  final String? gender;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? emergencyContact;
  final DateTime? joiningDate;
  final String? employmentStatus;
  final String? branch;
  final String? shiftInformation;
  final bool profileCompleted;
  final DateTime? profileCompletedAt;
  final int profileSetupStep;
  final String firstName;
  final String lastName;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? profilePhoto;
  final DateTime? dob;
  final String? nationality;
  final String? bloodGroup;
  final String? notes;

  const StaffMember({
    required this.id,
    this.employeeId,
    required this.name,
    required this.pin,
    required this.role,
    this.section,
    this.developerModeEnabled = false,
    this.department,
    this.age,
    this.gender,
    this.mobileNumber,
    this.email,
    this.address,
    this.emergencyContact,
    this.joiningDate,
    this.employmentStatus,
    this.branch,
    this.shiftInformation,
    this.profileCompleted = false,
    this.profileCompletedAt,
    this.profileSetupStep = 1,
    this.firstName = '',
    this.lastName = '',
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.profilePhoto,
    this.dob,
    this.nationality,
    this.bloodGroup,
    this.notes,
  });

  StaffMember copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? pin,
    StaffRole? role,
    String? section,
    bool? developerModeEnabled,
    String? department,
    int? age,
    String? gender,
    String? mobileNumber,
    String? email,
    String? address,
    String? emergencyContact,
    DateTime? joiningDate,
    String? employmentStatus,
    String? branch,
    String? shiftInformation,
    bool? profileCompleted,
    DateTime? profileCompletedAt,
    int? profileSetupStep,
    String? firstName,
    String? lastName,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? profilePhoto,
    DateTime? dob,
    String? nationality,
    String? bloodGroup,
    String? notes,
  }) {
    return StaffMember(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      section: section ?? this.section,
      developerModeEnabled: developerModeEnabled ?? this.developerModeEnabled,
      department: department ?? this.department,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      joiningDate: joiningDate ?? this.joiningDate,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      branch: branch ?? this.branch,
      shiftInformation: shiftInformation ?? this.shiftInformation,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
      profileSetupStep: profileSetupStep ?? this.profileSetupStep,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      dob: dob ?? this.dob,
      nationality: nationality ?? this.nationality,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      notes: notes ?? this.notes,
    );
  }
}
