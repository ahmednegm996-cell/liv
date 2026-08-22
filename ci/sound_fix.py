#!/usr/bin/env python3
"""UI click/tick WAVs + MainActivity SoundPool + generated-source compatibility fixes."""
from pathlib import Path
import math
import re
import struct
import wave

ROOT = Path(".")
raw_dir = ROOT / "android/app/src/main/res/raw"
raw_dir.mkdir(parents=True, exist_ok=True)
SR = 44100


def write_wav(path: Path, duration: float, freqs_amps, decay: float, peak: float):
    n = max(16, int(SR * duration))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for i in range(n):
            t = i / SR
            attack = 0.5 - 0.5 * math.cos(math.pi * min(1.0, t / 0.0018))
            env = attack * math.exp(-t * decay)
            tone = sum(a * math.sin(2.0 * math.pi * f * t) for f, a in freqs_amps)
            s = math.tanh(tone * env * peak)
            frames.extend(struct.pack("<h", int(s * 30000)))
        w.writeframes(frames)


write_wav(raw_dir / "liv_picker_tick.wav", 0.026, [(240, 0.55), (360, 0.28), (480, 0.10)], 155, 0.62)
write_wav(raw_dir / "liv_button_click.wav", 0.018, [(760, 0.50), (1140, 0.20), (560, 0.16)], 185, 0.72)
print("[sound_fix] WAVs written")

MAIN_KT = r'''package com.liv

import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "liv.feedback"
    private var soundPool: SoundPool? = null
    private var ageTickId: Int = 0
    private var buttonClickId: Int = 0
    private val loadedIds = HashSet<Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initSounds()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initSounds()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val volArg = call.argument<Double>("volume")
                val gain = (volArg?.toFloat() ?: 1.0f).coerceIn(0f, 1f)
                when (call.method) {
                    "tick" -> {
                        play(ageTickId, gain * 0.9f)
                        if (gain > 0.01f) vibrate(14)
                        result.success(null)
                    }
                    "buttonClick" -> {
                        play(buttonClickId, gain)
                        if (gain > 0.01f) vibrate(10)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initSounds() {
        if (soundPool != null) return
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val pool = SoundPool.Builder().setMaxStreams(6).setAudioAttributes(attrs).build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0 && sampleId != 0) loadedIds.add(sampleId)
        }
        soundPool = pool
        try { ageTickId = pool.load(this, R.raw.liv_picker_tick, 1) } catch (_: Exception) {}
        try { buttonClickId = pool.load(this, R.raw.liv_button_click, 1) } catch (_: Exception) {}
    }

    private fun play(soundId: Int, volume: Float) {
        val pool = soundPool ?: return
        if (soundId == 0 || volume <= 0.001f) return
        pool.play(soundId, volume, volume, 1, 0, 1.0f)
    }

    private fun vibrate(ms: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(VibratorManager::class.java)?.defaultVibrator?.vibrate(
                    VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION") v.vibrate(ms)
                }
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        soundPool?.setOnLoadCompleteListener(null)
        soundPool?.release()
        soundPool = null
        loadedIds.clear()
        super.onDestroy()
    }
}
'''

mains = list((ROOT / "android/app/src/main/kotlin").rglob("MainActivity.kt"))
if mains:
    mains[0].write_text(MAIN_KT, encoding="utf-8")
    print(f"[sound_fix] wrote {mains[0]}")

theme = ROOT / "lib/theme/app_theme.dart"
if theme.exists():
    t = theme.read_text(encoding="utf-8")
    aliases = '''\n  // Compatibility aliases used by the full LIV UI.\n  static const primary = purple;\n  static const accentTeal = teal;\n  static const cardDark = Color(0xFF1A1A23);\n  static const cardLight = Color(0xFFFFFFFF);\n  static const heartRed = Color(0xFFFF4D67);\n'''
    if 'static const primary = purple;' not in t:
        anchor = '  static const indigo = Color(0xFF6366F1);'
        if anchor not in t:
            raise SystemExit('[compat] AppColors anchor missing')
        t = t.replace(anchor, anchor + aliases, 1)
    theme.write_text(t, encoding="utf-8")
    print('[compat] AppColors aliases restored')

HELPERS = '''\n  Color mutedText([dynamic _a, dynamic _b, dynamic _c]) {\n    final c = _a is BuildContext ? _a : null;\n    return c == null ? Colors.white70 : secondaryText(c);\n  }\n\n  Color strongText([dynamic _a, dynamic _b, dynamic _c]) {\n    final c = _a is BuildContext ? _a : null;\n    if (c == null) return Colors.white;\n    return Theme.of(c).brightness == Brightness.dark ? Colors.white : Colors.black87;\n  }\n\n  Color subtleIcon([dynamic _a, dynamic _b, dynamic _c]) {\n    final c = _a is BuildContext ? _a : null;\n    return c == null ? Colors.white54 : secondaryText(c).withOpacity(0.75);\n  }\n'''

TARGETS = {
    'lib/screens/dreams_screen.dart': ['DreamsScreen'],
    'lib/screens/habits_screen.dart': ['HabitsScreen'],
}

for path, classes in TARGETS.items():
    p = ROOT / path
    if not p.exists():
        continue
    t = p.read_text(encoding='utf-8')
    for cls in classes:
        class_re = re.compile(r'class\s+' + re.escape(cls) + r'(?=\s|\{)')
        m = class_re.search(t)
        if not m:
            raise SystemExit(f'[compat] class not found: {cls} in {path}')
        brace = t.find('{', m.end())
        if brace < 0:
            raise SystemExit(f'[compat] class brace missing: {cls}')
        body_end = t.find('\n}', brace)
        if body_end < 0:
            body_end = len(t)
        body_prefix = t[brace:body_end]
        if 'Color subtleIcon(' not in body_prefix:
            t = t[:brace + 1] + HELPERS + t[brace + 1:]
    p.write_text(t, encoding='utf-8')
    print(f'[compat] helpers patched: {path}')

# HomeScreen may be supplied by the full LIV ZIP in an older architecture.
# Support both the current Stateful implementation and the older HomeScreen
# implementation without ever aborting the build because _HomeScreenState is absent.
home = ROOT / 'lib/screens/home_screen.dart'
if home.exists():
    ht = home.read_text(encoding='utf-8')
    state_match = re.search(r'class\s+_HomeScreenState(?=\s|\{)', ht)
    if state_match:
        brace = ht.find('{', state_match.end())
        if brace >= 0:
            body_end = ht.find('\n}', brace)
            if body_end < 0:
                body_end = len(ht)
            if 'Color subtleIcon(' not in ht[brace:body_end]:
                ht = ht[:brace + 1] + HELPERS + ht[brace + 1:]
                home.write_text(ht, encoding='utf-8')
                print('[compat] helpers patched: lib/screens/home_screen.dart')
            else:
                print('[compat] HomeScreen helpers already present')
    elif 'Color subtleIcon(' not in ht:
        # Old ZIP HomeScreen: provide safe top-level compatibility helpers.
        TOP_HELPERS = '''\n\nColor mutedText([dynamic _a, dynamic _b, dynamic _c]) {\n  final c = _a is BuildContext ? _a : null;\n  if (c == null) return Colors.white70;\n  return Theme.of(c).brightness == Brightness.dark ? Colors.white70 : Colors.black54;\n}\n\nColor strongText([dynamic _a, dynamic _b, dynamic _c]) {\n  final c = _a is BuildContext ? _a : null;\n  if (c == null) return Colors.white;\n  return Theme.of(c).brightness == Brightness.dark ? Colors.white : Colors.black87;\n}\n\nColor subtleIcon([dynamic _a, dynamic _b, dynamic _c]) {\n  final c = _a is BuildContext ? _a : null;\n  if (c == null) return Colors.white54;\n  return Theme.of(c).brightness == Brightness.dark ? Colors.white54 : Colors.black45;\n}\n'''
        ht += TOP_HELPERS
        home.write_text(ht, encoding='utf-8')
        print('[compat] helpers patched: lib/screens/home_screen.dart (legacy architecture)')

print('sound_fix + UI compatibility patch complete')
