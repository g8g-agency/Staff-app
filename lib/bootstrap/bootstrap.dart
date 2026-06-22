// lib/bootstrap/bootstrap.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/config/app_config.dart';
import '../core/config/environment.dart';
import '../core/network/secure_storage.dart';
import '../core/network/network_providers.dart';
import '../core/device/device_fingerprint_provider.dart';
import '../core/utils/logger.dart';
import '../app/app.dart';
import '../app/observers/provider_observer.dart';
import '../features/auth/presentation/state/auth_notifier.dart';

void bootstrap({
  required Environment environment,
  required String apiBaseUrl,
  required String websocketUrl,
  required bool enableSentry,
  String? supabaseUrl,
  String? supabaseAnonKey,
}) {
  // Initialize structured logger
  final talker = TalkerFlutter.init(
    settings: TalkerSettings(
      maxHistoryItems: 150,
      useConsoleLogs: true,
    ),
  );

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize environment configurations
    AppConfig.initialize(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      websocketUrl: websocketUrl,
      enableSentry: enableSentry,
    );

    // Initialize Hive local persistence layer
    await Hive.initFlutter();
    final apiCacheBox = await Hive.openBox<String>('api_cache');
    final offlineQueueBox = await Hive.openBox<String>('offline_writes');

    // Initialize Supabase instance using SecureTokenStorage (Keychain/Keystore wrapper)
    await Supabase.initialize(
      url: supabaseUrl ?? 'https://placeholder.supabase.co',
      anonKey: supabaseAnonKey ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder',
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );

    // Hydrate base system preferences first
    final sharedPreferences = await SharedPreferences.getInstance();
    final fingerprint = await DeviceFingerprintService.initFingerprint(sharedPreferences);

    // Auto-login platform session if not already logged in
    final client = Supabase.instance.client;
    final hasContext = sharedPreferences.getString('device_tenant_id') != null;

    if (!hasContext) {
      // FORCE login as super admin for development/kiosk mode
      try {
        await client.auth.signOut();
        await client.auth.signInWithPassword(
          email: 'admin@tableos.in',
          password: 'Admin@123456',
        );
        talker.info('[Supabase] Platform session established.');
      } catch (e) {
        talker.error('[Supabase] Failed to establish platform session: $e');
      }
    } else {
      talker.info('[Supabase] Registered device context detected. Skipping auto-login.');
      try {
        const secureStorage = SecureLocalStorage();
        final refreshToken = await secureStorage.read('refresh_token');
        if (refreshToken != null) {
          await client.auth.setSession(refreshToken);
          talker.info('[Supabase] Stored session recovered successfully.');
        } else {
          talker.warning('[Supabase] Stored context exists but no refresh token found.');
        }
      } catch (e) {
        talker.error('[Supabase] Failed to recover stored session: $e');
      }
    }


    // Create provider container
    final container = ProviderContainer(
      observers: [
        AppProviderObserver(),
      ],
      overrides: [
        // Expose SharedPreferences globally for dependencies
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // Override Hive boxes and Talker instances
        talkerProvider.overrideWithValue(talker),
        apiCacheBoxProvider.overrideWithValue(apiCacheBox),
        offlineQueueBoxProvider.overrideWithValue(offlineQueueBox),
        deviceFingerprintProvider.overrideWithValue(fingerprint),
      ],
    );

    // Pre-load staff list if device context exists
    try {
      await container.read(authNotifierProvider.notifier).loadInitialData();
    } catch (e) {
      talker.error('[Bootstrap] Failed to load initial data: $e');
    }

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const OrderlyyApp(),
      ),
    );
  }, (error, stack) {
    talker.handle(error, stack, '[Bootstrap Error] Unhandled Exception');
  });
}

// Global provider for shared preferences to inject into other data sources
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized inside Bootstrap.');
});
