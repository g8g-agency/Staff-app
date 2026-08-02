import 'package:flutter/foundation.dart';
import 'bootstrap/bootstrap.dart';
import 'core/config/environment.dart';

void main() {
  // Using machine LAN IP directly so the phone connects over WiFi.
  // No ADB reverse tunnel needed — phone and machine are on the same network.
  // Machine WiFi IP: 30.30.11.1 (update if your IP changes)
  const baseUrl = 'http://30.30.11.1:3001';
  const wsUrl = 'ws://30.30.11.1:3001/api/v1/realtime';

  bootstrap(
    environment: Environment.dev,
    apiBaseUrl: baseUrl,
    websocketUrl: wsUrl,
    enableSentry: false,
    supabaseUrl: 'https://mdwryhxnruprtuqonbwy.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd3J5aHhucnVwcnR1cW9uYnd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzU1MTEsImV4cCI6MjA5MDU1MTUxMX0.5hGdHHSzRnfENndmbL1pdiT2LsqhJCHkz1Fq2-8ADAY',
  );
}

