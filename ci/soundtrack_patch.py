#!/usr/bin/env python3
"""Wire meditation ambient into onboarding + AI with fade/mute. Safe to run twice."""
from pathlib import Path
import re
import base64
import shutil

ASSET_MP3 = "assets/audio/meditation_ambient.mp3"
ASSET_WAV = "assets/audio/meditation_ambient.wav"

out = Path(ASSET_MP3)
out.parent.mkdir(parents=True, exist_ok=True)

parts = sorted(Path("ci").glob("medpart*")) + sorted(Path("ci").glob("meditation.b64.p*"))
if parts:
    try:
        raw = "".join(p.read_text(encoding="utf-8").strip() for p in parts)
        data = base64.b64decode(raw)
        out.write_bytes(data)
        print("Decoded meditation asset:", out.stat().st_size, "bytes from", len(parts), "parts")
    except Exception as e:
        print("Base64 decode failed:", e)

if not out.exists() or out.stat().st_size < 500:
    for cand in [Path("assets/audio/welcome_ambient.wav"), Path("assets/audio/ai_ambient.wav")]:
        if cand.exists():
            shutil.copy(cand, Path(ASSET_WAV))
            print("Fallback copy:", cand)
            break

asset = ASSET_MP3 if out.exists() and out.stat().st_size >= 500 else (
    ASSET_WAV if Path(ASSET_WAV).exists() else "assets/audio/ai_ambient.wav"
)
print("Using soundtrack asset:", asset)

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

    needs_play = ("meditation_ambient" not in t) and ("playLoop(" not in t)
    if needs_play:
        if re.search(r"void\s+initState\s*\(\s*\)\s*\{", t):
            t = re.sub(
                r"(void\s+initState\s*\(\s*\)\s*\{\s*super\.initState\(\);)",
                r"""\1\n    AudioService.instance.playLoop(\n      '""" + asset + r"""',\n      volume: 0.26,\n      fadeIn: true,\n    );""",
                t,
                count=1,
            )
            changed = True
        else:
            inject = (
                "\n  @override\n  void initState() {\n    super.initState();\n"
                "    AudioService.instance.playLoop(\n      '%s',\n      volume: 0.26,\n      fadeIn: true,\n    );\n  }\n"
                % asset
            )
            t = re.sub(
                r"(class\s+_OnboardingScreenState[^{]*\{)",
                r"\1" + inject,
                t,
                count=1,
            )
            changed = True

    if "fadeOut" not in t and "completeOnboarding" in t:
        t = re.sub(
            r"(await\s+)?(state\.completeOnboarding\([^;]*\);)",
            r"await AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1800));\n    \1\2",
            t,
            count=1,
        )
        changed = True

    if "void dispose()" in t and "AudioService.instance.stop()" not in t:
        t = re.sub(
            r"(void\s+dispose\s*\(\s*\)\s*\{)",
            r"\1\n    try { AudioService.instance.stop(); } catch (_) {}",
            t,
            count=1,
        )
        changed = True

    if changed:
        ob.write_text(t, encoding="utf-8")
        print("Onboarding updated")
    else:
        print("Onboarding unchanged")
else:
    print("WARNING: no onboarding_screen.dart")

ai_files = list(Path("lib/screens").glob("*ai*chat*.dart"))
ai_files += list(Path("lib/screens").glob("*Ai*Chat*.dart"))
seen = set()
ai_files = [p for p in ai_files if not (str(p) in seen or seen.add(str(p)))]

for ai in ai_files:
    t = ai.read_text(encoding="utf-8")
    changed = False

    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
        changed = True

    if "ai_ambient.wav" in t:
        t = t.replace("assets/audio/ai_ambient.wav", asset)
        changed = True

    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']*'\s*(,\s*volume:\s*[0-9.]+)?\s*\)",
        "AudioService.instance.playLoop('%s', volume: 0.28, fadeIn: true)" % asset,
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

    if "_muted" not in t:
        t = re.sub(
            r"(class\s+_\w+State\s+extends\s+State<[^>]+>\s*\{)",
            r"\1\n  bool _muted = false;\n",
            t,
            count=1,
        )
        changed = True

    if "volume_up_rounded" not in t and "volume_off_rounded" not in t:
        mute_btn = """\n            IconButton(\n              tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',\n              icon: Icon(\n                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,\n                size: 22,\n              ),\n              onPressed: () async {\n                await AudioService.instance.toggleMute();\n                setState(() => _muted = AudioService.instance.isMuted);\n              },\n            ),\n"""
        if re.search(r"child:\s*Row\(\s*children:\s*\[", t):
            t = re.sub(
                r"(child:\s*Row\(\s*children:\s*\[)",
                r"\1" + mute_btn,
                t,
                count=1,
            )
            changed = True
        elif "appBar: AppBar(" in t:
            t = re.sub(
                r"(appBar:\s*AppBar\()",
                r"""\1\n        actions: [\n          IconButton(\n            tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',\n            icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),\n            onPressed: () async {\n              await AudioService.instance.toggleMute();\n              setState(() => _muted = AudioService.instance.isMuted);\n            },\n          ),\n        ],\n""",
                t,
                count=1,
            )
            changed = True

    if changed:
        ai.write_text(t, encoding="utf-8")
        print("AI updated:", ai)
    else:
        print("AI unchanged:", ai)

pub = Path("pubspec.yaml")
if pub.exists():
    t = pub.read_text(encoding="utf-8")
    if "meditation_ambient" not in t:
        t = t.replace(
            "  assets:\n",
            "  assets:\n    - assets/audio/meditation_ambient.mp3\n    - assets/audio/meditation_ambient.wav\n",
            1,
        )
        pub.write_text(t, encoding="utf-8")
        print("pubspec assets updated")

print("soundtrack_patch done OK")
