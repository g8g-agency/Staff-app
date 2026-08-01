// lib/features/alerts/services/order_alert_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class OrderAlertService {
  final AudioPlayer _audioPlayer;

  OrderAlertService() : _audioPlayer = AudioPlayer() {
    // Optionally pre-load sounds if needed, but simple playback is fine for now
  }

  Future<void> playNewOrderAlert() async {
    try {
      // In a real app, you'd place a sound in assets/sounds/order_alert.wav
      // For pilot, we assume the asset exists or fail gracefully
      await _audioPlayer.play(AssetSource('sounds/order_alert.wav'));
    } catch (e) {
      debugPrint('[OrderAlertService] Failed to play new order sound: $e');
    }
  }

  Future<void> playOrderReadyAlert() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/order_ready.mp3'));
    } catch (e) {
      debugPrint('[OrderAlertService] Failed to play order ready sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
