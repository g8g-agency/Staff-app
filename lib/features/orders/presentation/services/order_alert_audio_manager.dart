// lib/features/orders/presentation/services/order_alert_audio_manager.dart
//
// Manages playback of the incoming order alert sound.
// Plays immediately, repeats every 5 seconds, stops on accept/pass/expire.
// Max 30 seconds of sound (6 repetitions) to avoid infinite loops.

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class OrderAlertAudioManager {
  static final OrderAlertAudioManager _instance =
      OrderAlertAudioManager._internal();
  factory OrderAlertAudioManager() => _instance;
  OrderAlertAudioManager._internal();

  AudioPlayer? _player;
  Timer? _repeatTimer;
  bool _isPlaying = false;
  int _playCount = 0;
  double _volume = 1.0; // 0.0 – 1.0
  static const int _maxPlays = 6; // 6 × 5s = 30s max

  double get volume => _volume;

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _player?.setVolume(_volume);
    debugPrint('[OrderAlertAudio] Volume set to $_volume');
  }

  /// Start playing the alert sound immediately and repeat every 5 seconds.
  Future<void> startAlert() async {
    if (_isPlaying) return; // Already playing
    _isPlaying = true;
    _playCount = 0;

    _player = AudioPlayer();
    await _playSound();

    _repeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_playCount >= _maxPlays) {
        stopAlert();
        return;
      }
      await _playSound();
    });
  }

  Future<void> _playSound() async {
    if (!_isPlaying) return;
    _playCount++;
    try {
      await _player?.play(
        AssetSource('sounds/order_alert.wav'),
        volume: _volume,
      );
      debugPrint('[OrderAlertAudio] Playing alert sound (play #$_playCount)');
    } catch (e) {
      debugPrint('[OrderAlertAudio] Error playing sound: $e');
    }
  }

  /// Stop and clean up.
  Future<void> stopAlert() async {
    _isPlaying = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _playCount = 0;
    debugPrint('[OrderAlertAudio] Alert sound stopped.');
  }

  /// Play a distinct sound for when an order is ready for pickup.
  /// Falls back to order_alert.wav if order_ready.wav is not present.
  Future<void> playOrderReadySound() async {
    const assets = [
      'sounds/order_ready.wav',  // Preferred — add this file to use a distinct sound
      'sounds/order_alert.wav',  // Fallback — always exists
    ];
    for (final asset in assets) {
      try {
        final readyPlayer = AudioPlayer();
        await readyPlayer.play(
          AssetSource(asset),
          volume: _volume,
        );
        // Auto-dispose after it finishes
        Future.delayed(const Duration(seconds: 3), () => readyPlayer.dispose());
        debugPrint('[OrderAlertAudio] Playing order ready sound via $asset.');
        return;
      } catch (e) {
        debugPrint('[OrderAlertAudio] Asset $asset unavailable: $e — trying next.');
      }
    }
  }
}
