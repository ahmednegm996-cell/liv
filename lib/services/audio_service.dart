import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;

  /// صوت نقرة بسيط زي تطبيقات أبل (للـ pickers و Next)
  Future<void> tick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> playLoop(String assetPath, {double volume = 0.22}) async {
    try {
      if (_currentAsset == assetPath && _player.state == PlayerState.playing) {
        return;
      }
      await _player.stop();
      _currentAsset = assetPath;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (_) {
      // Missing asset or platform limitation — stay silent
    }
  }

  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
  }

  Future<void> stop() async {
    _currentAsset = null;
    await _player.stop();
  }
}
