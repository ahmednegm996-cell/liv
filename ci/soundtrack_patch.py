#!/usr/bin/env python3
"""Soundtrack wiring only.

Responsibilities:
- Ensure assets/audio/meditation_ambient.mp3 exists
- Ensure pubspec lists it once
- Ensure AI / onboarding use AudioService + that asset
- Invoke feature_patch for AI/gemini/l10n

Does NOT:
- Change HomeScreen circle size
- Convert tick() to buttonClick()
- Touch MainActivity / SoundPool
- Rewrite whole Dart files
"""
from pathlib import Path
import re
import sys
import runpy

# 1) feature_patch (AI overlay, gemini, l10n) — no circle resize there either
fp = Path("ci/feature_patch.py")
if fp.exists():
    runpy.run_path(str(fp))
    print("feature_patch applied")
else:
    print("WARNING: ci/feature_patch.py missing")

ASSET = "assets/audio/meditation_ambient.mp3"
LONG_ASSET = (
    "assets/audio/Meditation Music for a Calm Background  Quiet Echoes  Brioso.mp3"
)
# Must match AudioService.meditationVolume
MED_VOL = "1.0"

# 2) Canonical meditation file
Path("assets/audio").mkdir(parents=True, exist_ok=True)
canonical = Path(ASSET)
if not canonical.exists() or canonical.stat().st_size < 1000:
    long_p = Path(LONG_ASSET)
    if long_p.exists() and long_p.stat().st_size >= 1000:
        canonical.write_bytes(long_p.read_bytes())
        print(f"Copied long-name MP3 → {ASSET}")
    else:
        print(f"ERROR: Required meditation track missing: {ASSET}")
        sys.exit(1)

print(f"Using soundtrack asset: {ASSET} ({canonical.stat().st_size} bytes)")

# 3) pubspec assets once
pub = Path("pubspec.yaml")
if pub.exists():
    t = pub.read_text(encoding="utf-8")
    asset_entries = [ASSET]
    if Path("assets/icon/liv_icon.png").exists():
        asset_entries.append("assets/icon/liv_icon.png")
    assets_block = "  assets:\n" + "".join(f"    - {a}\n" for a in asset_entries)
    if re.search(r"(?m)^  assets:\n(?:    - .+\n)*", t):
        t = re.sub(r"(?m)^  assets:\n(?:    - .+\n)*", assets_block, t, count=1)
    elif re.search(r"(?m)^flutter:\n", t):
        t = re.sub(r"(?m)^(flutter:\n(?:  .+\n)*)", r"\1" + assets_block, t, count=1)
    else:
        t = t.rstrip() + "\n\nflutter:\n  uses-material-design: true\n" + assets_block
    pub.write_text(t, encoding="utf-8")
    print("pubspec assets:", asset_entries)

# 4) Onboarding — ensure AudioService + asset + fadeOut on complete (minimal)
ob = Path("lib/screens/onboarding_screen.dart")
if ob.exists():
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
    # Normalize any playLoop to canonical asset + volume
    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'\s*(,\s*volume:\s*[0-9.]+)?\s*(,\s*fadeIn:\s*(true|false))?\s*\)",
        f"AudioService.instance.playLoop('{ASSET}', volume: {MED_VOL}, fadeIn: true)",
        t,
    )
    if t2 != t:
        t = t2
        changed = True
    elif "playLoop(" not in t and re.search(r"void\s+initState\s*\(", t):
        t = re.sub(
            r"(void\s+initState\s*\(\s*\)\s*\{\s*super\.initState\(\);)",
            r"\1\n    AudioService.instance.playLoop(\n"
            f"      '{ASSET}',\n"
            f"      volume: {MED_VOL},\n"
            r"      fadeIn: true,\n"
            r"    );",
            t,
            count=1,
        )
        changed = True
    if "completeOnboarding" in t and "AudioService.instance.fadeOut" not in t:
        t2 = re.sub(
            r"((await\s+)?state\.completeOnboarding\([^;]*\);)",
            r"await AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1800));\n    \1",
            t,
            count=1,
        )
        if t2 != t:
            t = t2
            changed = True
    if changed:
        ob.write_text(t, encoding="utf-8")
        print("Onboarding audio wired")
    else:
        print("Onboarding audio already OK")
else:
    print("WARNING: onboarding_screen.dart missing")

# 5) AI chat screens — asset + volume only (keep tick/buttonClick as authored)
for ai in list(Path("lib/screens").glob("*ai*chat*.dart")):
    t = ai.read_text(encoding="utf-8")
    ch = False
    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
        ch = True
    for old in (
        "assets/audio/ai_ambient.wav",
        "assets/audio/welcome_ambient.wav",
        LONG_ASSET,
    ):
        if old in t:
            t = t.replace(old, ASSET)
            ch = True
    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'\s*(,\s*volume:\s*[0-9.]+)?\s*(,\s*fadeIn:\s*(true|false))?\s*\)",
        f"AudioService.instance.playLoop('{ASSET}', volume: {MED_VOL}, fadeIn: true)",
        t,
    )
    if t2 != t:
        t = t2
        ch = True
    # stop → fadeOut when leaving
    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        ch = True
    if ch:
        ai.write_text(t, encoding="utf-8")
        print("AI audio wired:", ai.name)

# 6) root_shell — stop → fadeOut only
rp = Path("lib/screens/root_shell.dart")
if rp.exists():
    t = rp.read_text(encoding="utf-8")
    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        rp.write_text(t, encoding="utf-8")
        print("root_shell: stop→fadeOut")

# NOTE: Age tick must stay tick(). Buttons should use buttonClick() in source.
# This script intentionally does NOT rewrite tick() → buttonClick().

print("soundtrack_patch done OK")
