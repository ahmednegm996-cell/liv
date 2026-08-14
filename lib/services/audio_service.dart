import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const MethodChannel _feedbackChannel = MethodChannel('liv.feedback');

  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;
  double _targetVolume = 0.28;
  bool _muted = false;
  Timer? _fadeTimer;
  bool _lifecycleAttached = false;

  bool get isMuted => _muted;
  bool get isPlaying => _player.state == PlayerState.playing;
  String? get currentAsset => _currentAsset;

  /// Attach once from app root to stop music when app is backgrounded/closed.
  void ensureLifecycleObserver() {
    if (_lifecycleAttached) return;
    _lifecycleAttached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(stop());
    }
  }

  /// Age picker: deeper bass click (native).
  Future<void> tick() async {
    try {
      await _feedbackChannel.invokeMethod<void>('tick');
      return;
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Normal UI buttons: different, slightly lighter deep click.
  Future<void> buttonClick() async {
    try {
      await _feedbackChannel.invokeMethod<void>('buttonClick');
      return;
    } catch (_) {}
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> playLoop(
    String assetPath, {
    double volume = 0.28,
    bool fadeIn = true,
    Duration fadeDuration = const Duration(milliseconds: 1400),
  }) async {
    try {
      ensureLifecycleObserver();
      _fadeTimer?.cancel();
      _targetVolume = volume.clamp(0.0, 1.0);

      if (_currentAsset == assetPath &&
          (_player.state == PlayerState.playing ||
              _player.state == PlayerState.paused)) {
        if (_player.state == PlayerState.paused) {
          await _player.resume();
        }
        if (!_muted) {
          await _player.setVolume(_targetVolume);
        }
        return;
      }

      await _player.stop();
      _currentAsset = assetPath;
      await _player.setReleaseMode(ReleaseMode.loop);

      final startVol = (fadeIn && !_muted) ? 0.0 : (_muted ? 0.0 : _targetVolume);
      await _player.setVolume(startVol);
      await _player.play(
        AssetSource(assetPath.replaceFirst('assets/', '')),
      );

      if (fadeIn && !_muted) {
        await _fadeTo(_targetVolume, fadeDuration);
      }
    } catch (_) {}
  }

  Future<void> fadeOut({
    Duration duration = const Duration(milliseconds: 1600),
  }) async {
    try {
      if (_player.state != PlayerState.playing) {
        await stop();
        return;
      }
      await _fadeTo(0.0, duration);
      await stop();
    } catch (_) {
      await stop();
    }
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    try {
      if (muted) {
        await _player.setVolume(0.0);
      } else if (_player.state == PlayerState.playing) {
        await _player.setVolume(_targetVolume);
      }
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    await setMuted(!_muted);
  }

  Future<void> setVolume(double v) async {
    _targetVolume = v.clamp(0.0, 1.0);
    if (!_muted) {
      await _player.setVolume(_targetVolume);
    }
  }

  Future<void> stop() async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _currentAsset = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_lifecycleAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleAttached = false;
    }
    _fadeTimer?.cancel();
    await _player.dispose();
  }

  Future<void> _fadeTo(double target, Duration duration) async {
    _fadeTimer?.cancel();
    final completer = Completer<void>();
    final steps = 20;
    final stepMs = (duration.inMilliseconds / steps).round().clamp(20, 200);

    double current;
    if (target < 0.01) {
      current = _muted ? 0.0 : _targetVolume;
    } else {
      current = 0.0;
    }

    final delta = (target - current) / steps;
    var step = 0;

    _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) async {
      step++;
      current = (current + delta).clamp(0.0, 1.0);
      try {
        if (!_muted || target == 0.0) {
          await _player.setVolume(current);
        }
      } catch (_) {}
      if (step >= steps) {
        t.cancel();
        _fadeTimer = null;
        try {
          await _player.setVolume(_muted ? 0.0 : target);
        } catch (_) {}
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future.timeout(
      duration + const Duration(milliseconds: 400),
      onTimeout: () {},
    );
  }
}
