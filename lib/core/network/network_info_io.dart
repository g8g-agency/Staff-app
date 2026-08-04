// lib/core/network/network_info_io.dart
import 'dart:io';

Future<bool> checkConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) return true;
  } on SocketException catch (_) {}

  // LAN backend fallback — check if machine's WiFi IP is reachable at port 3001
  // This allows the app to detect connectivity even without WAN access.
  try {
    final socket = await Socket.connect('30.30.11.1', 3001, timeout: const Duration(milliseconds: 1500));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
