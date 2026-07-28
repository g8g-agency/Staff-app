// lib/features/orders/presentation/services/order_alert_audio_manager.dart
//
// Manages playback of the incoming order alert sound.
// Plays immediately, repeats every 5 seconds, stops on accept/pass/expire.
// Max 30 seconds of sound (6 repetitions) to avoid infinite loops.
// Also drives continuous vibration pattern in sync with each sound burst.

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OrderAlertAudioManager {
  static final OrderAlertAudioManager _instance =
      OrderAlertAudioManager._internal();
  factory OrderAlertAudioManager() => _instance;
  OrderAlertAudioManager._internal();

  AudioPlayer? _player;
  Timer? _repeatTimer;
  Timer? _vibrateTimer;
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
  /// Also fires a strong vibration burst in sync with each sound repetition.
  Future<void> startAlert() async {
    if (_isPlaying) return; // Already playing
    _isPlaying = true;
    _playCount = 0;

    _player = AudioPlayer();
    await _playSound();
    _vibrateAlertBurst(); // Immediate vibration on first alert

    _repeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_playCount >= _maxPlays) {
        stopAlert();
        return;
      }
      await _playSound();
      _vibrateAlertBurst(); // Vibrate in sync with each sound repeat
    });
  }

  /// Fires a pattern: 3 × heavy impacts spaced 120ms apart.
  /// Runs asynchronously so it doesn't block audio playback.
  void _vibrateAlertBurst() {
    _vibrateTimer?.cancel();
    int _count = 0;
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (_count >= 3 || !_isPlaying) {
        t.cancel();
        _vibrateTimer = null;
        return;
      }
      HapticFeedback.heavyImpact();
      _count++;
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

  /// Stop sound and vibration, clean up all resources.
  Future<void> stopAlert() async {
    _isPlaying = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _playCount = 0;
    debugPrint('[OrderAlertAudio] Alert sound + vibration stopped.');
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
