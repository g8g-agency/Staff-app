// lib/features/auth/presentation/state/auth_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/staff_member.dart';
import 'auth_state.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/branch.dart';

import '../../../../core/storage/device_context_store.dart';
import '../../providers/auth_repository_provider.dart';
import '../../../../core/runtime/runtime.dart';
import '../../../../core/network/secure_storage.dart';
import 'package:flutter/foundation.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> loadInitialData() async {
    // No longer loading mock public organizations.
    // Instead, this will just check if we have a saved context.
    final store = ref.read(deviceContextStoreProvider);
    debugPrint('[AuthNotifier] loadInitialData called. hasContext: ${store.hasContext}, branchId: ${store.branchId}, branchName: ${store.branchName}');
    if (store.hasContext) {
      state = state.copyWith(
        selectedBranch: Branch(
          id: store.branchId ?? '',
          name: store.branchName ?? 'Main Branch',
          status: BranchStatus.open,
          syncPercentage: '100%',
          activeStaff: 0,
        ),
        selectedOrg: Organization(id: store.tenantId ?? '', name: 'Orderlyy'),
      );
      // Load staff for the saved branch
      await loadStaffForBranch();
    }
  }

  List<StaffMember> _staffMembers = [];
  List<StaffMember> get mockStaff => _staffMembers;

  Future<void> loadStaffForBranch() async {
    final store = ref.read(deviceContextStoreProvider);
    if (!store.hasContext) return;

    // Need an admin/device token to fetch staff
    const secureStorage = SecureLocalStorage();
    final token = await secureStorage.read('access_token') ?? '';
    final repo = ref.read(authRepositoryProvider);
    _staffMembers = await repo.getStaffForBranch(
      store.tenantId!,
      store.branchId!,
      token,
    );
    state = state.copyWith();
  }

  Future<Map<String, dynamic>?> adminLogin(
    String email,
    String password,
  ) async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.adminLogin(email, password);
  }

  Future<void> selectAndSaveBranch(
    String tenantId,
    String branchId,
    String branchName,
  ) async {
    final store = ref.read(deviceContextStoreProvider);
    await store.saveContext(
      tenantId: tenantId,
      branchId: branchId,
      branchName: branchName,
    );

    state = state.copyWith(
      selectedBranch: Branch(
        id: branchId,
        name: branchName,
        status: BranchStatus.open,
        syncPercentage: '100%',
        activeStaff: 0,
      ),
      selectedOrg: Organization(id: tenantId, name: 'Orderlyy'),
    );

    await loadStaffForBranch();
  }

  Future<bool> login(String employeeId, String pin) async {
    state = state.copyWith(errorMessage: null);

    final repo = ref.read(authRepositoryProvider);
    final staff = await repo.loginWithPin(_staffMembers, employeeId, pin);

    if (staff != null) {
      state = state.copyWith(loggedInStaff: staff, isLocked: false);
      return true;
    } else {
      state = state.copyWith(
        errorMessage: 'Invalid PIN code. Please try again.',
      );
      return false;
    }
  }

  Future<void> startShift(StaffRole role, String section) async {
    if (state.loggedInStaff == null) {
      state = state.copyWith(errorMessage: 'Cannot start shift: Staff is not logged in.');
      return;
    }
    if (state.selectedBranch == null) {
      state = state.copyWith(errorMessage: 'Cannot start shift: Branch is not selected.');
      return;
    }

    final updatedStaff = state.loggedInStaff!.copyWith(
      role: role,
      section: section,
    );

    // Hydrate runtime session using backend-authoritative data
    final hydrator = ref.read(runtimeSessionHydratorProvider);
    final result = await hydrator.hydrateSession(
      branchId: state.selectedBranch!.id,
      staffId: updatedStaff.id,
    );

    if (result.success && result.session != null) {
      // Setup runtime epoch and notify orchestrator
      final orchestrator = ref.read(runtimeOrchestratorProvider);
      orchestrator.startSession(
        branchId: state.selectedBranch!.id,
        staffId: updatedStaff.id,
      );

      state = state.copyWith(
        loggedInStaff: updatedStaff,
        isShiftStarted: true,
        shiftStartTime: DateTime.now(),
        isLocked: false,
      );
    } else {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'Failed to start shift',
      );
    }
  }

  void lockSession() {
    state = state.copyWith(isLocked: true);
  }

  bool unlockSession(String pin) {
    if (state.loggedInStaff?.pin == pin) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    state = state.copyWith(errorMessage: 'Incorrect PIN code.');
    return false;
  }

  void updateStaffSession(StaffMember updatedStaff) {
    state = state.copyWith(loggedInStaff: updatedStaff);
  }

  void endShift() {
    state = state.copyWith(
      isShiftStarted: false,
      shiftStartTime: null,
      loggedInStaff: null,
    );
  }

  void logout() {
    state = const AuthState();
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (state.loggedInStaff == null) return false;
    
    const secureStorage = SecureLocalStorage();
    final token = await secureStorage.read('runtime_token') ?? '';
    
    final repo = ref.read(authRepositoryProvider);
    
    // Add staff_id to the request since the runtime_token belongs to the admin who registered the device
    final dataToSend = Map<String, dynamic>.from(profileData);
    dataToSend['staff_id'] = state.loggedInStaff!.id;
    
    final success = await repo.updateProfile(token, dataToSend);
    
    if (success) {
      // Re-fetch staff data to reflect changes
      await loadStaffForBranch();
      
      // Update logged in staff with new data locally just in case
      final staff = state.loggedInStaff!;
      final updatedStaff = staff.copyWith(
        profileCompleted: profileData['profile_completed'] ?? staff.profileCompleted,
        profileSetupStep: profileData['profile_setup_step'] ?? staff.profileSetupStep,
        firstName: profileData['first_name'] ?? staff.firstName,
        lastName: profileData['last_name'] ?? staff.lastName,
        emergencyContactName: profileData['emergency_contact_name'] ?? staff.emergencyContactName,
        emergencyContactNumber: profileData['emergency_contact_number'] ?? staff.emergencyContactNumber,
        mobileNumber: profileData['mobile_number'] ?? staff.mobileNumber,
        address: profileData['address'] ?? staff.address,
        gender: profileData['gender'] ?? staff.gender,
      );
      state = state.copyWith(loggedInStaff: updatedStaff);
    }
    
    return success;
  }
}
