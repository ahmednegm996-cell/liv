from pathlib import Path
import math
import re
import struct
import wave


# ============================================================
# LIV NATIVE FEEDBACK PATCH
# ============================================================
#
# This script runs AFTER "flutter create".
#
# It does four things:
#
# 1. Generates a tiny picker tick WAV.
# 2. Installs it into Android res/raw.
# 3. Adds a native MethodChannel named "liv.feedback".
# 4. Connects the channel to:
#       SoundPool + VibrationEffect.EFFECT_TICK
#
# The important reason this happens here:
#
# The GitHub Actions workflow creates the Android project during CI.
# Therefore native Android modifications must happen AFTER flutter create.
# ============================================================


ROOT = Path(".")


# ============================================================
# 1. Generate the tiny tick sound
# ============================================================

raw_dir = (
    ROOT
    / "android"
    / "app"
    / "src"
    / "main"
    / "res"
    / "raw"
)

raw_dir.mkdir(
    parents=True,
    exist_ok=True,
)

wav_path = raw_dir / "liv_picker_tick.wav"


SAMPLE_RATE = 44100
DURATION = 0.032
FRAME_COUNT = int(
    SAMPLE_RATE * DURATION
)


with wave.open(
    str(wav_path),
    "wb",
) as wav:

    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(SAMPLE_RATE)

    frames = bytearray()

    for i in range(FRAME_COUNT):

        t = i / SAMPLE_RATE

        attack_time = 0.0012

        attack = min(
            1.0,
            t / attack_time,
        )

        decay = math.exp(
            -t * 120.0
        )

        tone = (
            0.55
            * math.sin(
                2.0
                * math.pi
                * 2900.0
                * t
            )
            +
            0.20
            * math.sin(
                2.0
                * math.pi
                * 5200.0
                * t
            )
        )

        sample = (
            tone
            * attack
            * decay
        )

        sample = max(
            -1.0,
            min(
                1.0,
                sample,
            ),
        )

        frames.extend(
            struct.pack(
                "<h",
                int(
                    sample
                    * 32767
                ),
            )
        )

    wav.writeframes(
        frames
    )


print(
    "Created:",
    wav_path,
)


# ============================================================
# 2. Find MainActivity.kt
# ============================================================

kotlin_root = (
    ROOT
    / "android"
    / "app"
    / "src"
    / "main"
    / "kotlin"
)


main_files = list(
    kotlin_root.rglob(
        "MainActivity.kt"
    )
)


if not main_files:

    raise SystemExit(
        "ERROR: MainActivity.kt "
        "was not generated."
    )


main_activity = main_files[0]


original = main_activity.read_text(
    encoding="utf-8"
)


# ============================================================
# 3. Determine package name
# ============================================================

package_match = re.search(
    r"^\s*package\s+([^\s]+)",
    original,
    re.MULTILINE,
)


if not package_match:

    raise SystemExit(
        "ERROR: Could not determine "
        "MainActivity package."
    )


package_name = (
    package_match
    .group(1)
    .strip()
)


# ============================================================
# 4. Generate complete native MainActivity
# ============================================================

native_activity = f"""package {package_name}

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.media.ToneGenerator
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {{

    companion object {{
        private const val CHANNEL = "liv.feedback"
    }}

    private var soundPool: SoundPool? = null

    private var tickSoundId: Int = 0

    private var soundLoaded = false

    private var toneGenerator: ToneGenerator? = null


    override fun onCreate(
        savedInstanceState: Bundle?
    ) {{

        super.onCreate(
            savedInstanceState
        )


        // ----------------------------------------------------
        // Low latency Android UI sound
        // ----------------------------------------------------

        val audioAttributes =
            AudioAttributes.Builder()
                .setUsage(
                    AudioAttributes.USAGE_ASSISTANCE_SONIFICATION
                )
                .setContentType(
                    AudioAttributes.CONTENT_TYPE_SONIFICATION
                )
                .build()


        soundPool =
            SoundPool.Builder()
                .setMaxStreams(4)
                .setAudioAttributes(
                    audioAttributes
                )
                .build()


        soundPool?.setOnLoadCompleteListener {{
            _,
            sampleId,
            status ->

            if (
                status == 0 &&
                sampleId == tickSoundId
            ) {{
                soundLoaded = true
            }}
        }}


        tickSoundId =
            soundPool?.load(
                this,
                R.raw.liv_picker_tick,
                1
            ) ?: 0


        // ----------------------------------------------------
        // Emergency fallback sound
        // ----------------------------------------------------

        toneGenerator =
            try {{
                ToneGenerator(
                    AudioManager.STREAM_MUSIC,
                    35
                )
            }} catch (
                _: Exception
            ) {{
                null
            }}
    }}


    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {{

        super.configureFlutterEngine(
            flutterEngine
        )


        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,

            CHANNEL

        ).setMethodCallHandler {{
            call,
            result ->

            when (call.method) {{

                "tick" -> {{

                    playTickSound()

                    playTickHaptic()

                    result.success(
                        null
                    )
                }}


                else -> {

                    result.notImplemented()
                }
            }}
        }}
    }}


    // ========================================================
    // SOUND
    // ========================================================

    private fun playTickSound() {{

        if (
            soundLoaded &&
            tickSoundId != 0
        ) {{

            soundPool?.play(

                tickSoundId,

                0.34f,
                0.34f,

                10,

                0,

                1.0f
            )

            return
        }


        // SoundPool may still be loading
        // during the first picker movement.

        try {{

            toneGenerator?.startTone(
                ToneGenerator.TONE_PROP_BEEP,
                25
            )

        }} catch (
            _: Exception
        ) {{}}
    }}


    // ========================================================
    // HAPTIC
    // ========================================================

    private fun playTickHaptic() {{

        try {{

            val vibrator: Vibrator =

                if (
                    Build.VERSION.SDK_INT >=
                    Build.VERSION_CODES.S
                ) {{

                    getSystemService(
                        VibratorManager::class.java
                    ).defaultVibrator

                }} else {{

                    @Suppress("DEPRECATION")

                    getSystemService(
                        Context.VIBRATOR_SERVICE
                    ) as Vibrator
                }}


            if (
                !vibrator.hasVibrator()
            ) {{
                return
            }}


            // Android 12+

            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.S
            ) {{

                val supported =
                    vibrator.areEffectsSupported(
                        VibrationEffect.EFFECT_TICK
                    )


                if (
                    supported.isNotEmpty() &&
                    supported[0] ==
                    Vibrator.VIBRATION_EFFECT_SUPPORT_YES
                ) {{

                    vibrator.vibrate(
                        VibrationEffect
                            .createPredefined(
                                VibrationEffect.EFFECT_TICK
                            )
                    )

                    return
                }}
            }}


            // Android 10 / 11

            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.Q
            ) {{

                vibrator.vibrate(
                    VibrationEffect
                        .createPredefined(
                            VibrationEffect.EFFECT_TICK
                        )
                )

                return
            }}


            // Android 8+

            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.O
            ) {{

                vibrator.vibrate(
                    VibrationEffect
                        .createOneShot(
                            8L,
                            70
                        )
                )

                return
            }}


            // Old Android

            @Suppress("DEPRECATION")

            vibrator.vibrate(
                8L
            )

        }} catch (
            _: Exception
        ) {{}}
    }}


    // ========================================================
    // CLEANUP
    // ========================================================

    override fun onDestroy() {{

        try {{
            soundPool?.release()
        }} catch (
            _: Exception
        ) {{}}


        soundPool = null


        try {{
            toneGenerator?.release()
        }} catch (
            _: Exception
        ) {{}}


        toneGenerator = null


        super.onDestroy()
    }}
}}
"""


main_activity.write_text(
    native_activity,
    encoding="utf-8",
)


print(
    "Patched:",
    main_activity,
)


# ============================================================
# 5. Patch onboarding age picker
# ============================================================

onboarding = (
    ROOT
    / "lib"
    / "screens"
    / "onboarding_screen.dart"
)


if onboarding.exists():

    text = onboarding.read_text(
        encoding="utf-8"
    )


    # --------------------------------------------------------
    # Import AudioService
    # --------------------------------------------------------

    if (
        "services/audio_service.dart"
        not in text
    ):

        imports = (
            "import '../services/audio_service.dart';\n"
        )

        marker = (
            "import 'package:flutter/material.dart';"
        )

        if marker in text:

            text = text.replace(
                marker,
                marker
                + "\n"
                + imports,
                1,
            )


    # --------------------------------------------------------
    # Replace old tick helper
    # --------------------------------------------------------

    new_tick_method = """
  void _tickAgeItem() {
    AudioService.instance.tick();
  }
"""


    text, replacements = re.subn(
        r"""
        \s*void\s+_tickAgeItem\s*\(\s*\)
        \s*\{
        .*?
        \n\s*\}
        """,
        new_tick_method,
        text,
        count=1,
        flags=re.S | re.X,
    )


    # If no existing helper was found,
    # insert one before _tick().

    if "_tickAgeItem()" not in text:

        marker = (
            "  Future<void> _tick()"
        )

        if marker in text:

            text = text.replace(
                marker,
                new_tick_method
                + "\n"
                + marker,
                1,
            )


    # --------------------------------------------------------
    # Replace picker callback
    # --------------------------------------------------------

    old_callback = """
onSelectedItemChanged: (i) async {
                  await _tick();
                  setState(() => _age = i + 12);
                },
"""


    new_callback = """
onSelectedItemChanged: (i) {
                  final nextAge = i + 12;

                  if (nextAge == _age) {
                    return;
                  }

                  setState(() {
                    _age = nextAge;
                  });

                  _tickAgeItem();
                },
"""


    if old_callback in text:

        text = text.replace(
            old_callback,
            new_callback,
            1,
        )


    # --------------------------------------------------------
    # Remove direct SystemSound / Haptic calls from age helper
    # --------------------------------------------------------

    text = re.sub(
        r"""
        void\s+_tickAgeItem\s*\(\s*\)
        \s*\{
        \s*try\s*\{
        \s*SystemSound\.play.*?
        \s*\}\s*catch\s*\(_\)\s*\{\}
        \s*try\s*\{
        \s*HapticFeedback\.selectionClick\(\);
        \s*\}\s*catch\s*\(_\)\s*\{\}
        \s*\}
        """,
        new_tick_method.strip(),
        text,
        count=1,
        flags=re.S | re.X,
    )


    onboarding.write_text(
        text,
        encoding="utf-8",
    )


    print(
        "Patched age picker:",
        onboarding,
    )

else:

    print(
        "WARNING: onboarding_screen.dart "
        "not found during feedback patch."
    )


print(
    "========================================"
)

print(
    "LIV FEEDBACK PATCH COMPLETE"
)

print(
    "Sound:",
    wav_path
)

print(
    "Native:",
    main_activity
)

print(
    "========================================"
)