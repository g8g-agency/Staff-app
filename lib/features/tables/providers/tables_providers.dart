// lib/features/tables/providers/tables_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../bootstrap/bootstrap.dart';
import '../application/use_cases/update_table_status_use_case.dart';
import '../application/use_cases/watch_tables_use_case.dart';
import '../data/datasources/local/tables_local_datasource_impl.dart';
import '../data/datasources/remote/tables_remote_datasource.dart';
import '../data/datasources/remote/tables_remote_datasource_impl.dart';
import '../data/repositories/tables_repository_impl.dart';
import '../domain/repositories/tables_repository.dart';
import '../../../../core/network/network_providers.dart';
import '../../auth/presentation/state/auth_notifier.dart';

// 1. Remote Datasource — uses DioClient (backend REST API) instead of Supabase client
// Token is read lazily from SecureLocalStorage inside the datasource on each request.
final tablesRemoteDatasourceProvider = Provider<TablesRemoteDatasource>((ref) {
  final dio = ref.watch(dioClientProvider);
  final authState = ref.watch(authNotifierProvider);
  final branchId = authState.selectedBranch?.id ?? '';
  return TablesRemoteDatasourceImpl(dio, branchId);
});

// 2. Local Datasource
final tablesLocalDatasourceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TablesLocalDatasourceImpl(prefs);
});

// 3. Repository
final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  final remote = ref.watch(tablesRemoteDatasourceProvider);
  final local = ref.watch(tablesLocalDatasourceProvider);
  final network = ref.watch(networkInfoProvider);
  final offlineQueue = ref.watch(offlineQueueManagerProvider);

  return TablesRepositoryImpl(
    remote: remote,
    local: local,
    networkInfo: network,
    offlineQueue: offlineQueue,
  );
});

// 4. Use Cases
final updateTableStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(tablesRepositoryProvider);
  return UpdateTableStatusUseCase(repository);
});

final watchTablesUseCaseProvider = Provider((ref) {
  final repository = ref.watch(tablesRepositoryProvider);
  return WatchTablesUseCase(repository);
});
