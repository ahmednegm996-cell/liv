from pathlib import Path
import math
import re
import struct
import wave


ROOT = Path(".")


# ============================================================
# CONFIG
# ============================================================

CHANNEL_NAME = "liv.feedback"
TICK_METHOD = "tick"


# ============================================================
# 1. Generate a tiny native picker tick WAV
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
DURATION = 0.028
FRAME_COUNT = int(SAMPLE_RATE * DURATION)

with wave.open(str(wav_path), "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(SAMPLE_RATE)

    frames = bytearray()

    for i in range(FRAME_COUNT):
        t = i / SAMPLE_RATE

        # Very short attack + fast decay = subtle UI tick.
        attack = min(1.0, t / 0.001)
        decay = math.exp(-t * 145.0)

        tone = (
            0.58 * math.sin(
                2.0 * math.pi * 3000.0 * t
            )
            +
            0.18 * math.sin(
                2.0 * math.pi * 5400.0 * t
            )
        )

        sample = tone * attack * decay

        sample = max(
            -1.0,
            min(1.0, sample)
        )

        frames.extend(
            struct.pack(
                "<h",
                int(sample * 32767)
            )
        )

    wav.writeframes(frames)

print(f"[feedback] created {wav_path}")


# ============================================================
# 2. Locate generated MainActivity.kt
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
    kotlin_root.rglob("MainActivity.kt")
)

if not main_files:
    raise SystemExit(
        "[feedback] ERROR: MainActivity.kt was not generated."
    )

main_activity = main_files[0]

old_main = main_activity.read_text(
    encoding="utf-8"
)


# ============================================================
# 3. Detect Kotlin package
# ============================================================

package_match = re.search(
    r"^\s*package\s+([A-Za-z0-9_.]+)",
    old_main,
    re.MULTILINE,
)

if not package_match:
    raise SystemExit(
        "[feedback] ERROR: Could not determine Kotlin package."
    )

package_name = package_match.group(1)

print(
    f"[feedback] Kotlin package: {package_name}"
)


# ============================================================
# 4. Replace MainActivity with native feedback bridge
# ============================================================

native_main = f"""package {package_name}

import android.content.Context
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


class MainActivity : FlutterActivity() {{

    companion object {{
        private const val CHANNEL = "{CHANNEL_NAME}"
    }}

    private var soundPool: SoundPool? = null
    private var tickSoundId: Int = 0
    private var soundLoaded: Boolean = false


    override fun onCreate(
        savedInstanceState: Bundle?
    ) {{
        super.onCreate(savedInstanceState)

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
                .setAudioAttributes(audioAttributes)
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
    }}


    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {{
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,
            CHANNEL
        ).setMethodCallHandler {{
            call,
            result ->

            when (call.method) {{

                "{TICK_METHOD}" -> {{
                    playTickSound()
                    playTickHaptic()
                    result.success(null)
                }}

                else -> {{
                    result.notImplemented()
                }}
            }}
        }}
    }}


    private fun playTickSound() {{

        if (
            soundLoaded &&
            tickSoundId != 0
        ) {{

            soundPool?.play(
                tickSoundId,
                0.42f,
                0.42f,
                10,
                0,
                1.0f
            )
        }}
    }}


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


            if (!vibrator.hasVibrator()) {{
                return
            }}


            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.Q
            ) {{

                vibrator.vibrate(
                    VibrationEffect.createPredefined(
                        VibrationEffect.EFFECT_TICK
                    )
                )

            }} else if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.O
            ) {{

                vibrator.vibrate(
                    VibrationEffect.createOneShot(
                        8L,
                        70
                    )
                )

            }} else {{

                @Suppress("DEPRECATION")
                vibrator.vibrate(8L)
            }}

        }} catch (
            _: Exception
        ) {{
            // Never allow feedback failure to crash the app.
        }}
    }}


    override fun onDestroy() {{

        try {{
            soundPool?.release()
        }} catch (
            _: Exception
        ) {{
        }}

        soundPool = null

        super.onDestroy()
    }}
}}
"""


main_activity.write_text(
    native_main,
    encoding="utf-8"
)

print(
    f"[feedback] native MainActivity installed: {main_activity}"
)


# ============================================================
# 5. Locate AudioService
# ============================================================

audio_service = (
    ROOT
    / "lib"
    / "services"
    / "audio_service.dart"
)

if not audio_service.exists():
    raise SystemExit(
        "[feedback] ERROR: lib/services/audio_service.dart is missing."
    )

audio_text = audio_service.read_text(
    encoding="utf-8"
)


# ============================================================
# 6. Verify AudioService uses the correct MethodChannel
# ============================================================

if CHANNEL_NAME not in audio_text:
    raise SystemExit(
        "[feedback] ERROR: AudioService does not use "
        f"'{CHANNEL_NAME}'."
    )

if "invokeMethod<void>('tick')" not in audio_text:
    raise SystemExit(
        "[feedback] ERROR: AudioService does not invoke tick()."
    )

print(
    "[feedback] AudioService -> MethodChannel verified"
)


# ============================================================
# 7. Locate onboarding_screen.dart
# ============================================================

onboarding = (
    ROOT
    / "lib"
    / "screens"
    / "onboarding_screen.dart"
)

if not onboarding.exists():
    raise SystemExit(
        "[feedback] ERROR: onboarding_screen.dart is missing."
    )

text = onboarding.read_text(
    encoding="utf-8"
)


# ============================================================
# 8. Ensure AudioService import exists
# ============================================================

audio_import = (
    "import '../services/audio_service.dart';"
)

if audio_import not in text:

    material_import = (
        "import 'package:flutter/material.dart';"
    )

    if material_import in text:

        text = text.replace(
            material_import,
            material_import
            + "\n"
            + audio_import,
            1,
        )

    else:

        text = (
            audio_import
            + "\n"
            + text
        )

    print(
        "[feedback] added AudioService import"
    )


# ============================================================
# 9. Replace _tickAgeItem() safely
#
# IMPORTANT:
# We do NOT try to parse nested Dart braces.
# We locate the method boundaries using known method names.
# ============================================================

method_pattern = re.compile(
    r"""
    (?P<indent>^[ \t]*)
    void[ \t]+_tickAgeItem[ \t]*\([ \t]*\)[ \t]*\{
    .*?
    ^[ \t]*\}
    (?=\s*(?:Future<void>|void|Widget|@override|String|int|bool|static|final|late|\}))
    """,
    re.DOTALL | re.MULTILINE | re.VERBOSE,
)

method_match = method_pattern.search(text)

new_age_method = """  void _tickAgeItem() {
    AudioService.instance.tick();
  }
"""


if method_match:

    text = (
        text[:method_match.start()]
        + new_age_method.rstrip()
        + text[method_match.end():]
    )

    print(
        "[feedback] replaced existing _tickAgeItem()"
    )

else:

    # The ux_period_patch.py normally creates _tickAgeItem().
    # If it doesn't exist, create it immediately before _tick().
    tick_method = re.search(
        r"^[ \t]*Future<void>[ \t]+_tick[ \t]*\(",
        text,
        re.MULTILINE,
    )

    if not tick_method:

        raise SystemExit(
            "[feedback] ERROR: Neither _tickAgeItem() "
            "nor _tick() was found."
        )

    insert_at = tick_method.start()

    text = (
        text[:insert_at]
        + new_age_method
        + "\n"
        + text[insert_at:]
    )

    print(
        "[feedback] inserted _tickAgeItem()"
    )


# ============================================================
# 10. Replace the EXACT callback generated by ux_period_patch.py
#
# This is intentionally NOT a generic nested-brace regex.
# ux_period_patch.py creates this exact logical callback.
# ============================================================

old_callback_patterns = [

    # Current callback generated by ux_period_patch.py
    re.compile(
        r"""
        onSelectedItemChanged\s*:\s*
        \(i\)\s*
        async\s*
        \{
        \s*await\s+_tick\(\);\s*
        setState\s*\(\s*\(\)\s*=>\s*_age\s*=\s*i\s*\+\s*12\s*\)\s*;
        \s*\},
        """,
        re.DOTALL | re.VERBOSE,
    ),

    # Same callback without async.
    re.compile(
        r"""
        onSelectedItemChanged\s*:\s*
        \(i\)\s*
        \{
        \s*await\s+_tick\(\);\s*
        setState\s*\(\(\)\s*=>\s*_age\s*=\s*i\s*\+\s*12\s*\)\s*;
        \s*\},
        """,
        re.DOTALL | re.VERBOSE,
    ),

    # Callback already partially patched.
    re.compile(
        r"""
        onSelectedItemChanged\s*:\s*
        \(i\)\s*
        \{
        \s*final\s+next\s*=\s*i\s*\+\s*12\s*;
        \s*if\s*\(\s*next\s*==\s*_age\s*\)\s*return\s*;
        \s*setState\s*\(\(\)\s*=>\s*_age\s*=\s*next\s*\)\s*;
        \s*_tickAgeItem\(\)\s*;
        \s*\},
        """,
        re.DOTALL | re.VERBOSE,
    ),

    # Callback from the newer patch style.
    re.compile(
        r"""
        onSelectedItemChanged\s*:\s*
        \(i\)\s*
        \{
        \s*final\s+nextAge\s*=\s*i\s*\+\s*12\s*;
        \s*if\s*\(\s*nextAge\s*==\s*_age\s*\)\s*\{
        \s*return\s*;
        \s*\}
        \s*setState\s*\(\s*\{
        \s*_age\s*=\s*nextAge\s*;
        \s*\}\s*\)\s*;
        \s*_tickAgeItem\(\)\s*;
        \s*\},
        """,
        re.DOTALL | re.VERBOSE,
    ),
]


new_callback = """onSelectedItemChanged: (i) {
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


callback_replaced = False

for pattern in old_callback_patterns:

    match = pattern.search(text)

    if match:

        text = (
            text[:match.start()]
            + new_callback
            + text[match.end():]
        )

        callback_replaced = True

        print(
            "[feedback] Age Picker callback patched"
        )

        break


if not callback_replaced:

    # Do not guess.
    # If the source shape changed, fail instead of creating
    # another APK without verified feedback.
    raise SystemExit(
        "[feedback] ERROR: Could not safely identify the "
        "Age Picker callback created by ux_period_patch.py."
    )


# ============================================================
# 11. Write onboarding
# ============================================================

onboarding.write_text(
    text,
    encoding="utf-8"
)

print(
    f"[feedback] wrote {onboarding}"
)


# ============================================================
# 12. Verify the FINAL Dart source
# ============================================================

final_text = onboarding.read_text(
    encoding="utf-8"
)

verification_errors = []


if audio_import not in final_text:
    verification_errors.append(
        "AudioService import is missing."
    )


if not re.search(
    r"void\s+_tickAgeItem\s*\(\s*\)\s*\{",
    final_text,
):
    verification_errors.append(
        "_tickAgeItem() is missing."
    )


if (
    "AudioService.instance.tick();"
    not in final_text
):
    verification_errors.append(
        "AudioService.instance.tick() is missing."
    )


if (
    "onSelectedItemChanged: (i)"
    not in final_text
):
    verification_errors.append(
        "Age Picker callback is missing."
    )


if (
    "_tickAgeItem();"
    not in final_text
):
    verification_errors.append(
        "Age Picker does not call _tickAgeItem()."
    )


if not re.search(
    r"_age\s*=\s*nextAge\s*;",
    final_text,
):
    verification_errors.append(
        "Age state assignment is missing."
    )


if not re.search(
    r"final\s+nextAge\s*=\s*i\s*\+\s*12\s*;",
    final_text,
):
    verification_errors.append(
        "Age calculation is missing."
    )


# ============================================================
# 13. Verify native Kotlin
# ============================================================

native_text = main_activity.read_text(
    encoding="utf-8"
)


if f'private const val CHANNEL = "{CHANNEL_NAME}"' not in native_text:
    verification_errors.append(
        "Native MethodChannel declaration missing."
    )


if 'setMethodCallHandler' not in native_text:
    verification_errors.append(
        "Native MethodChannel handler missing."
    )


if '"tick" ->' not in native_text:
    verification_errors.append(
        "Native tick method missing."
    )


if "SoundPool" not in native_text:
    verification_errors.append(
        "SoundPool missing."
    )


if "R.raw.liv_picker_tick" not in native_text:
    verification_errors.append(
        "Native WAV resource is not loaded."
    )


if "VibrationEffect.EFFECT_TICK" not in native_text:
    verification_errors.append(
        "Android EFFECT_TICK missing."
    )


if "playTickSound()" not in native_text:
    verification_errors.append(
        "playTickSound() missing."
    )


if "playTickHaptic()" not in native_text:
    verification_errors.append(
        "playTickHaptic() missing."
    )


# ============================================================
# 14. Verify WAV
# ============================================================

if not wav_path.exists():
    verification_errors.append(
        "Picker WAV was not generated."
    )

else:

    try:

        with wave.open(
            str(wav_path),
            "rb",
        ) as wav:

            if wav.getnchannels() != 1:
                verification_errors.append(
                    "Picker WAV must be mono."
                )

            if wav.getsampwidth() != 2:
                verification_errors.append(
                    "Picker WAV must be 16-bit."
                )

            if wav.getframerate() != SAMPLE_RATE:
                verification_errors.append(
                    "Picker WAV has unexpected sample rate."
                )

            if wav.getnframes() <= 0:
                verification_errors.append(
                    "Picker WAV contains no audio frames."
                )

    except Exception as exc:

        verification_errors.append(
            f"Could not validate WAV: {exc}"
        )


# ============================================================
# 15. Verify Android Manifest
# ============================================================

manifest = (
    ROOT
    / "android"
    / "app"
    / "src"
    / "main"
    / "AndroidManifest.xml"
)

if not manifest.exists():

    verification_errors.append(
        "AndroidManifest.xml is missing."
    )

else:

    manifest_text = manifest.read_text(
        encoding="utf-8"
    )

    if (
        "android.permission.VIBRATE"
        not in manifest_text
    ):
        verification_errors.append(
            "VIBRATE permission is missing."
        )


# ============================================================
# 16. Final hard failure
# ============================================================

if verification_errors:

    print("")
    print("==============================================")
    print("LIV FEEDBACK PATCH FAILED")
    print("==============================================")

    for error in verification_errors:
        print(f"ERROR: {error}")

    print("")
    print(
        "The APK build is intentionally stopped."
    )

    raise SystemExit(1)


# ============================================================
# 17. SUCCESS
# ============================================================

print("")
print("==============================================")
print("LIV FEEDBACK PATCH VERIFIED SUCCESSFULLY")
print("==============================================")
print("")
print("OK  AudioService")
print("OK  MethodChannel: liv.feedback")
print("OK  Native SoundPool")
print("OK  Picker WAV")
print("OK  Native Android TICK haptic")
print("OK  VIBRATE permission")
print("OK  Age Picker callback")
print("OK  Age Picker -> _tickAgeItem()")
print("OK  _tickAgeItem() -> AudioService.instance.tick()")
print("")
print(
    "The source is now wired as:"
)
print("")
print(
    "Age Picker"
    " -> _tickAgeItem()"
    " -> AudioService"
    " -> MethodChannel"
    " -> Android SoundPool + Haptic"
)
print("")
print(
    "Feedback patch completed."
)
print("==============================================")