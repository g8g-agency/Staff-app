// lib/features/tables/providers/table_bill_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/secure_storage.dart';

final tableBillProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, sessionIdOrTableId) async {
  if (sessionIdOrTableId.isEmpty) return null;
  final dio = ref.watch(dioClientProvider);
  const storage = SecureLocalStorage();
  String? token = await storage.read('runtime_token');
  if (token == null || token.isEmpty) {
    token = await storage.read('access_token');
  }

  try {
    final response = await dio.get(
      '/api/v1/sessions/$sessionIdOrTableId/bill',
      options: Options(
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      ),
    );

    if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
  } catch (_) {
    return null;
  }
  return null;
});
