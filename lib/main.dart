import 'package:flutter/foundation.dart';
import 'bootstrap/bootstrap.dart';
import 'core/config/environment.dart';

void main() {
  final isWeb = kIsWeb;
  final baseUrl = isWeb ? 'http://localhost:3001' : 'http://127.0.0.1:3001';
  final wsUrl = isWeb ? 'ws://localhost:3001/api/v1/realtime' : 'ws://127.0.0.1:3001/api/v1/realtime';

  bootstrap(
    environment: Environment.dev,
    bootstrap(
      environment: Environment.dev,
      apiBaseUrl: baseUrl,
      websocketUrl: wsUrl,
    enableSentry: false,
    supabaseUrl: 'https://mdwryhxnruprtuqonbwy.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd3J5aHhucnVwcnR1cW9uYnd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzU1MTEsImV4cCI6MjA5MDU1MTUxMX0.5hGdHHSzRnfENndmbL1pdiT2LsqhJCHkz1Fq2-8ADAY',
  );
}
