import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const MethodChannel _feedbackChannel =
      MethodChannel('liv.feedback');

  final AudioPlayer _player = AudioPlayer();

  String? _currentAsset;

  /// Short native picker feedback.
  ///
  /// Android:
  /// - SoundPool plays a very short tick.
  /// - VibrationEffect produces a light native tick.
  ///
  /// iOS / unsupported platforms:
  /// - Falls back to Flutter haptic/system feedback.
  Future<void> tick() async {
    try {
      await _feedbackChannel.invokeMethod<void>('tick');
      return;
    } catch (_) {
      // Native bridge unavailable.
      // Fall back to Flutter feedback.
    }

    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}

    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> playLoop(
    String assetPath, {
    double volume = 0.22,
  }) async {
    try {
      if (_currentAsset == assetPath &&
          _player.state == PlayerState.playing) {
        return;
      }

      await _player.stop();

      _currentAsset = assetPath;

      await _player.setReleaseMode(
        ReleaseMode.loop,
      );

      await _player.setVolume(
        volume.clamp(0.0, 1.0),
      );

      await _player.play(
        AssetSource(
          assetPath.replaceFirst('assets/', ''),
        ),
      );
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    await _player.setVolume(
      v.clamp(0.0, 1.0),
    );
  }

  Future<void> stop() async {
    _currentAsset = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}