package com.liv

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
                val volArg = call.argument<Double>("volume")
                val gain = (volArg?.toFloat() ?: 1.0f).coerceIn(0f, 1f)
                when (call.method) {
                    "tick" -> {
                        play(ageTickId, gain)
                        if (gain > 0.01f) vibrate(14)
                        result.success(null)
                    }
                    "buttonClick" -> {
                        play(buttonClickId, gain * 0.85f)
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
        soundPool = pool
        try {
            ageTickId = pool.load(this, R.raw.liv_picker_tick, 1)
        } catch (_: Exception) {
        }
        try {
            buttonClickId = pool.load(this, R.raw.liv_button_click, 1)
        } catch (_: Exception) {
        }
    }

    private fun play(soundId: Int, volume: Float) {
        val pool = soundPool ?: return
        if (soundId == 0 || volume <= 0.001f) return
        pool.play(soundId, volume, volume, 1, 0, 1.0f)
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
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
