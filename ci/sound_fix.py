#!/usr/bin/env python3
"""Generate age/button click WAVs and wire MainActivity MethodChannel."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(".")
raw_dir = ROOT / "android/app/src/main/res/raw"
raw_dir.mkdir(parents=True, exist_ok=True)
SR = 44100

def write_wav(path: Path, duration: float, freqs_amps, decay: float):
    n = int(SR * duration)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for i in range(n):
            t = i / SR
            attack = min(1.0, t / 0.001)
            d = math.exp(-t * decay)
            tone = sum(a * math.sin(2.0 * math.pi * f * t) for f, a in freqs_amps)
            s = max(-1.0, min(1.0, tone * attack * d))
            frames.extend(struct.pack("<h", int(s * 32767)))
        w.writeframes(frames)

write_wav(raw_dir / "liv_picker_tick.wav", 0.05, [(180, 0.75), (90, 0.55), (360, 0.22)], 70)
write_wav(raw_dir / "liv_button_click.wav", 0.035, [(520, 0.6), (780, 0.28), (260, 0.22)], 110)
print("[sound_fix] WAVs written")

MAIN_KT = r'''package com.liv

import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initSounds()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tick" -> {
                        play(ageTickId, 1.0f)
                        vibrate(28)
                        result.success(null)
                    }
                    "buttonClick" -> {
                        play(buttonClickId, 0.9f)
                        vibrate(18)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initSounds() {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        soundPool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(attrs).build()
        try { ageTickId = soundPool?.load(this, R.raw.liv_picker_tick, 1) ?: 0 } catch (_: Exception) {}
        try { buttonClickId = soundPool?.load(this, R.raw.liv_button_click, 1) ?: 0 } catch (_: Exception) {}
    }

    private fun play(soundId: Int, volume: Float) {
        if (soundId != 0) soundPool?.play(soundId, volume, volume, 1, 0, 1.0f)
    }

    private fun vibrate(ms: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(VibratorManager::class.java)
                vm?.defaultVibrator?.vibrate(
                    VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(ms)
                }
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
'''

mains = list((ROOT / "android/app/src/main/kotlin").rglob("MainActivity.kt"))
if not mains:
    print("[sound_fix] WARNING: MainActivity.kt not found")
else:
    mains[0].write_text(MAIN_KT, encoding="utf-8")
    print(f"[sound_fix] wrote {mains[0]}")
print("sound_fix done")
