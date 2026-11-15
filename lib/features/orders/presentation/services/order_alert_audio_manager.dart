// lib/features/orders/presentation/services/order_alert_audio_manager.dart
//
// Manages continuous playback of the incoming order alert sound.
// Plays immediately, repeats every 5 seconds while unacknowledged alerts remain,
// and stops when all alerts are acknowledged/claimed or dismissed.
// Drives continuous haptic vibration pattern in sync with each sound burst.

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

  double get volume => _volume;
  bool get isPlaying => _isPlaying;

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _player?.setVolume(_volume);
    debugPrint('[OrderAlertAudio] Volume set to $_volume');
  }

  /// Start playing the alert sound immediately and repeat continuously every 5 seconds
  /// until explicitly stopped when all pending orders are acknowledged.
  Future<void> startAlert() async {
    if (_isPlaying) {
      debugPrint('[OrderAlertAudio] Alert already playing — skipping redundant start.');
      return; // Avoid multiple simultaneous players
    }
    _isPlaying = true;
    _playCount = 0;

    try {
      _player = AudioPlayer();
      // Configure audio context: request audio focus and route to speaker
      await _player?.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    } catch (e) {
      debugPrint('[OrderAlertAudio] Failed to set audio context: $e');
    }

    await _playSound();
    _vibrateAlertBurst();

    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isPlaying) {
        _repeatTimer?.cancel();
        _repeatTimer = null;
        return;
      }
      await _playSound();
      _vibrateAlertBurst();
    });
  }

  /// Fires a pattern: 3 × heavy impacts spaced 150ms apart.
  void _vibrateAlertBurst() {
    _vibrateTimer?.cancel();
    int count = 0;
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (count >= 3 || !_isPlaying) {
        t.cancel();
        _vibrateTimer = null;
        return;
      }
      HapticFeedback.heavyImpact();
      count++;
    });
  }

  Future<void> _playSound() async {
    if (!_isPlaying || _player == null) return;
    _playCount++;
    try {
      await _player?.stop();
      await _player?.play(
        AssetSource('sounds/order_alert.wav'),
        volume: _volume,
      );
      debugPrint('[OrderAlertAudio] Playing alert sound burst (repetition #$_playCount)');
    } catch (e) {
      debugPrint('[OrderAlertAudio] Error playing sound: $e');
    }
  }

  /// Stop sound and vibration, and release all audio resources.
  Future<void> stopAlert() async {
    if (!_isPlaying && _player == null) return;
    _isPlaying = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (e) {
      debugPrint('[OrderAlertAudio] Error disposing player: $e');
    }
    _player = null;
    _playCount = 0;
    debugPrint('[OrderAlertAudio] Alert sound + vibration stopped and resources released.');
  }

  /// Play a distinct sound for when an order is ready for pickup.
  Future<void> playOrderReadySound() async {
    const assets = [
      'sounds/order_ready.wav',
      'sounds/order_alert.wav',
    ];
    for (final asset in assets) {
      try {
        final readyPlayer = AudioPlayer();
        await readyPlayer.play(
          AssetSource(asset),
          volume: _volume,
        );
        Future.delayed(const Duration(seconds: 3), () => readyPlayer.dispose());
        debugPrint('[OrderAlertAudio] Playing order ready sound via $asset.');
        return;
      } catch (e) {
        debugPrint('[OrderAlertAudio] Asset $asset unavailable: $e — trying next.');
      }
    }
  }
}
