#!/usr/bin/env python3
"""Wire full meditation track into onboarding + AI with continuity. No old ambient fallbacks."""
from pathlib import Path
import re
import sys

ASSET = "assets/audio/meditation_ambient.mp3"
LONG_ASSET = (
    "assets/audio/Meditation Music for a Calm Background  Quiet Echoes  Brioso.mp3"
)

audio_dir = Path("assets/audio")
audio_dir.mkdir(parents=True, exist_ok=True)

canonical = Path(ASSET)
if not canonical.exists() or canonical.stat().st_size < 1000:
    long_p = Path(LONG_ASSET)
    if long_p.exists() and long_p.stat().st_size >= 1000:
        canonical.write_bytes(long_p.read_bytes())
        print(f"Copied long-name MP3 → {ASSET} ({canonical.stat().st_size} bytes)")
    else:
        print(
            f"ERROR: Required meditation track missing.\n"
            f"  expected: {ASSET}\n"
            f"  or:       {LONG_ASSET}"
        )
        sys.exit(1)

if canonical.stat().st_size < 1000:
    print(f"ERROR: {ASSET} is too small ({canonical.stat().st_size} bytes)")
    sys.exit(1)

print(f"Using soundtrack asset: {ASSET} ({canonical.stat().st_size} bytes)")

# --- pubspec: declare meditation track (+ icon if present) ---
pub = Path("pubspec.yaml")
if pub.exists():
    t = pub.read_text(encoding="utf-8")
    t = re.sub(
        r"\n\s*-\s*assets/audio/(welcome_ambient|ai_ambient|meditation_ambient)\.(wav|mp3)\s*",
        "\n",
        t,
    )
    if ASSET not in t:
        if re.search(r"^\s*assets:\s*$", t, re.M):
            t = re.sub(
                r"(^\s*assets:\s*$)",
                r"\1\n    - " + ASSET,
                t,
                count=1,
                flags=re.M,
            )
        elif "assets:" in t:
            t = t.replace("  assets:\n", f"  assets:\n    - {ASSET}\n", 1)
        else:
            t += f"\nflutter:\n  assets:\n    - {ASSET}\n"
    if Path("assets/icon/liv_icon.png").exists() and "assets/icon/liv_icon.png" not in t:
        t = t.replace(
            f"    - {ASSET}\n",
            f"    - {ASSET}\n    - assets/icon/liv_icon.png\n",
            1,
        )
    pub.write_text(t, encoding="utf-8")
    print("pubspec assets updated for meditation track")

# --- onboarding ---
ob = Path("lib/screens/onboarding_screen.dart")
if not ob.exists():
    print("ERROR: onboarding_screen.dart missing")
    sys.exit(1)

t = ob.read_text(encoding="utf-8")
changed = False

if "audio_service.dart" not in t:
    if "import '../services/app_state.dart';" in t:
        t = t.replace(
            "import '../services/app_state.dart';",
            "import '../services/app_state.dart';\nimport '../services/audio_service.dart';",
            1,
        )
    else:
        t = "import '../services/audio_service.dart';\n" + t
    changed = True

# Remove injected fadeOut on complete that break continuity
t2 = re.sub(
    r"\s*await\s+AudioService\.instance\.fadeOut\([^;]*\);\s*\n",
    "\n",
    t,
)
if t2 != t:
    t = t2
    changed = True

if "playLoop(" not in t:
    if re.search(r"void\s+initState\s*\(\s*\)\s*\{", t):
        t = re.sub(
            r"(void\s+initState\s*\(\s*\)\s*\{\s*super\.initState\(\);)",
            r"\1\n    AudioService.instance.playLoop(\n"
            r"      '" + ASSET + r"',\n"
            r"      volume: 0.26,\n"
            r"      fadeIn: true,\n"
            r"    );",
            t,
            count=1,
        )
        changed = True
    else:
        inject = (
            "\n  @override\n  void initState() {\n    super.initState();\n"
            f"    AudioService.instance.playLoop(\n      '{ASSET}',\n"
            "      volume: 0.26,\n      fadeIn: true,\n    );\n  }\n"
        )
        t = re.sub(
            r"(class\s+_OnboardingScreenState[^{]*\{)",
            r"\1" + inject,
            t,
            count=1,
        )
        changed = True
else:
    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'",
        f"AudioService.instance.playLoop(\n      '{ASSET}'",
        t,
    )
    if t2 != t:
        t = t2
        changed = True

# Do NOT stop player on onboarding dispose (continuity → AI)
if re.search(r"void\s+dispose\s*\([^)]*\)\s*\{[^}]*AudioService\.instance\.stop", t, re.S):
    t = re.sub(
        r"(void\s+dispose\s*\([^)]*\)\s*\{)\s*try\s*\{\s*AudioService\.instance\.stop\(\);\s*\}\s*catch\s*\([^)]*\)\s*\{\s*\}",
        r"\1",
        t,
    )
    t = re.sub(
        r"(void\s+dispose\s*\([^)]*\)\s*\{)\s*AudioService\.instance\.stop\(\);\s*",
        r"\1",
        t,
    )
    changed = True

if changed:
    ob.write_text(t, encoding="utf-8")
    print("Onboarding updated for continuous meditation track")
else:
    print("Onboarding already OK")

# --- AI chat screens ---
ai_files = list(Path("lib/screens").glob("*ai*chat*.dart"))
ai_files += list(Path("lib/screens").glob("*Ai*Chat*.dart"))
seen = set()
ai_files = [p for p in ai_files if str(p) not in seen and not seen.add(str(p))]

for ai in ai_files:
    t = ai.read_text(encoding="utf-8")
    changed = False

    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
        changed = True

    for old in (
        "assets/audio/ai_ambient.wav",
        "assets/audio/welcome_ambient.wav",
        "assets/audio/meditation_ambient.wav",
        LONG_ASSET,
    ):
        if old in t:
            t = t.replace(old, ASSET)
            changed = True

    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'\s*(,\s*volume:\s*[0-9.]+)?\s*(,\s*fadeIn:\s*(true|false))?\s*\)",
        f"AudioService.instance.playLoop('{ASSET}', volume: 0.28, fadeIn: true)",
        t,
    )
    if t2 != t:
        t = t2
        changed = True

    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        changed = True

    if "volume_up_rounded" not in t and "volume_off_rounded" not in t:
        if re.search(r"class\s+_\w+State\s+extends\s+State<", t) and "_muted" not in t:
            t = re.sub(
                r"(class\s+_\w+State\s+extends\s+State<[^>]+>\s*\{)",
                r"\1\n  bool _muted = false;\n",
                t,
                count=1,
            )
            changed = True
        mute_btn = """
            IconButton(
              tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
              icon: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 22,
              ),
              onPressed: () async {
                await AudioService.instance.toggleMute();
                setState(() => _muted = AudioService.instance.isMuted);
              },
            ),
"""
        if re.search(r"child:\s*Row\(\s*children:\s*\[", t):
            t = re.sub(
                r"(child:\s*Row\(\s*children:\s*\[)",
                r"\1" + mute_btn,
                t,
                count=1,
            )
            changed = True

    if changed:
        ai.write_text(t, encoding="utf-8")
        print("AI updated:", ai)
    else:
        print("AI unchanged:", ai)

for rp in [Path("lib/screens/root_shell.dart")]:
    if not rp.exists():
        continue
    t = rp.read_text(encoding="utf-8")
    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        rp.write_text(t, encoding="utf-8")
        print("root_shell: stop → fadeOut on leave AI")

print("soundtrack_patch done OK")
