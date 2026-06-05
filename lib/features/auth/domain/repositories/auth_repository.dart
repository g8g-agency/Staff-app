import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../entities/organization.dart';
import '../entities/branch.dart';
import '../entities/staff_member.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/secure_storage.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final DioClient _dio;

  AuthRepository(this._supabase, this._dio);

  Future<Map<String, dynamic>?> adminLogin(String email, String password) async {
    try {
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_fingerprint': _dio.deviceFingerprint,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        final accessToken = data['access_token'];
        
        const secureStorage = SecureLocalStorage();
        await secureStorage.write('access_token', accessToken);
        
        // Use the token to fetch the context
        final contextResponse = await _dio.get(
          '/api/v1/context/bootstrap',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );

        if (contextResponse.statusCode == 200 && contextResponse.data['success']) {
          return {
            'tenantId': contextResponse.data['data']['tenant']['id'],
            'branches': contextResponse.data['data']['branches'],
            'access_token': accessToken,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AuthRepository] adminLogin error: $e');
      return null;
    }
  }

  Future<List<StaffMember>> getStaffForBranch(String tenantId, String branchId, String token) async {
    try {
      // NOTE: This requires the backend /api/v1/tenants/:tenantId/staff endpoint to be implemented and authenticated!
      // In a real POS, we fetch staff via the tenant route using a device token or admin token.
      final response = await _dio.get(
        '/api/v1/tenants/$tenantId/staff',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skip_cache': true},
        ),
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((row) {
        return StaffMember(
          id: row['id'] as String,
          employeeId: row['employee_id'] as String?,
          name: row['name'] as String,
          pin: row['pin'] as String? ?? '',
          role: _mapRole(row['role'] as String?),
          section: row['section'] as String?,
          developerModeEnabled: row['developer_mode_enabled'] as bool? ?? false,
          profileCompleted: row['profile_completed'] as bool? ?? false,
          profileSetupStep: row['profile_setup_step'] as int? ?? 1,
          firstName: row['first_name'] as String? ?? '',
          lastName: row['last_name'] as String? ?? '',
          profileCompletedAt: row['profile_completed_at'] != null ? DateTime.tryParse(row['profile_completed_at']) : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('[AuthRepository] getStaffForBranch error: $e');
      return [];
    }
  }

  Future<StaffMember?> loginWithPin(List<StaffMember> staffList, String employeeId, String pin) async {
    try {
      return staffList.firstWhere(
        (staff) => staff.pin == pin && (staff.employeeId == employeeId || staff.id == employeeId),
      );
    } catch (e) {
      return null;
    }
  }

  StaffRole _mapRole(String? role) {
    if (role == null) return StaffRole.waiter;
    switch (role.toLowerCase()) {
      case 'owner':
      case 'manager':
        return StaffRole.manager;
      case 'kitchen':
      case 'kds':
      case 'kdsoperator':
        return StaffRole.kdsOperator;
      case 'runner':
        return StaffRole.runner;
      case 'host':
        return StaffRole.host;
      case 'waiter':
      case 'server':
      default:
        return StaffRole.waiter;
    }
  }
  Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '/api/v1/auth/staff/me/profile',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      debugPrint('[AuthRepository] updateProfile error: $e');
      return false;
    }
  }
}
