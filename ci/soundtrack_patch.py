#!/usr/bin/env python3
"""Wire meditation track into onboarding + AI. Continuity, fade on finish, higher AI volume."""
from pathlib import Path
import re
import sys

ASSET = "assets/audio/meditation_ambient.mp3"
LONG_ASSET = "assets/audio/Meditation Music for a Calm Background  Quiet Echoes  Brioso.mp3"

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
    print("pubspec assets rewritten:", asset_entries)

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

if "playLoop(" not in t:
    if re.search(r"void\s+initState\s*\(\s*\)\s*\{", t):
        t = re.sub(
            r"(void\s+initState\s*\(\s*\)\s*\{\s*super\.initState\(\);)",
            r"\1\n    AudioService.instance.playLoop(\n      '" + ASSET + r"',\n      volume: 0.26,\n      fadeIn: true,\n    );",
            t,
            count=1,
        )
        changed = True

# Fade-out when questions fully finish
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

# Do not stop on onboarding dispose
t2 = re.sub(
    r"(void\s+dispose\s*\([^)]*\)\s*\{)\s*(try\s*\{\s*)?AudioService\.instance\.stop\(\);\s*(\}\s*catch\s*\([^)]*\)\s*\{\s*\})?",
    r"\1",
    t,
)
if t2 != t:
    t = t2
    changed = True

if changed:
    ob.write_text(t, encoding="utf-8")
    print("Onboarding updated")
else:
    print("Onboarding already OK")

for ai in list(Path("lib/screens").glob("*ai*chat*.dart")):
    t = ai.read_text(encoding="utf-8")
    ch = False
    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
        ch = True
    for old in ("assets/audio/ai_ambient.wav", "assets/audio/welcome_ambient.wav", LONG_ASSET):
        if old in t:
            t = t.replace(old, ASSET)
            ch = True
    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'\s*(,\s*volume:\s*[0-9.]+)?\s*(,\s*fadeIn:\s*(true|false))?\s*\)",
        f"AudioService.instance.playLoop('{ASSET}', volume: 0.55, fadeIn: true)",
        t,
    )
    if t2 != t:
        t = t2
        ch = True
    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        ch = True
    if ch:
        ai.write_text(t, encoding="utf-8")
        print("AI updated:", ai)

rp = Path("lib/screens/root_shell.dart")
if rp.exists():
    t = rp.read_text(encoding="utf-8")
    if "AudioService.instance.stop()" in t:
        t = t.replace(
            "AudioService.instance.stop()",
            "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
        )
        rp.write_text(t, encoding="utf-8")
        print("root_shell fadeOut on leave AI")

for hp in Path("lib/screens").glob("*.dart"):
    if hp.name.startswith("onboarding"):
        continue
    ht = hp.read_text(encoding="utf-8")
    if "AudioService.instance.tick()" in ht:
        hp.write_text(ht.replace("AudioService.instance.tick()", "AudioService.instance.buttonClick()"), encoding="utf-8")
        print("buttonClick wired:", hp)

print("soundtrack_patch done OK")
