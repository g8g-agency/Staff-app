// lib/features/alerts/services/order_alert_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../orders/presentation/services/order_alert_audio_manager.dart';

class OrderAlertService {
  final AudioPlayer _audioPlayer;

  OrderAlertService() : _audioPlayer = AudioPlayer();

  Future<void> playNewOrderAlert() async {
    try {
      // Delegate to looping audio + vibration manager until acknowledged
      await OrderAlertAudioManager().startAlert();
    } catch (e) {
      debugPrint('[OrderAlertService] Failed to play new order sound: $e');
    }
  }

  Future<void> stopAlert() async {
    try {
      await OrderAlertAudioManager().stopAlert();
    } catch (e) {
      debugPrint('[OrderAlertService] Failed to stop order alert: $e');
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
