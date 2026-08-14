#!/usr/bin/env python3
from pathlib import Path
import re, base64, shutil

out_mp3 = Path("assets/audio/meditation_ambient.mp3")
out_wav = Path("assets/audio/meditation_ambient.wav")
out_mp3.parent.mkdir(parents=True, exist_ok=True)

parts = sorted(Path("ci").glob("meditation.b64.p*")) + sorted(Path("ci").glob("med.p*"))
if parts:
    try:
        b64 = "".join(p.read_text(encoding="utf-8").strip() for p in parts)
        out_mp3.write_bytes(base64.b64decode(b64))
        print("Wrote meditation from base64", out_mp3.stat().st_size)
    except Exception as e:
        print("decode failed", e)

if not out_mp3.exists() or (out_mp3.exists() and out_mp3.stat().st_size < 1000):
    for cand in [Path("assets/audio/welcome_ambient.wav"), Path("assets/audio/ai_ambient.wav")]:
        if cand.exists():
            shutil.copy(cand, out_wav)
            print("FALLBACK ambient", cand)
            break

asset = "assets/audio/meditation_ambient.mp3" if out_mp3.exists() and out_mp3.stat().st_size > 1000 else (
    "assets/audio/meditation_ambient.wav" if out_wav.exists() else "assets/audio/ai_ambient.wav"
)
print("Using asset", asset)

ob = Path("lib/screens/onboarding_screen.dart")
if ob.exists():
    t = ob.read_text(encoding="utf-8")
    if "audio_service.dart" not in t:
        t = t.replace(
            "import '../services/app_state.dart';",
            "import '../services/app_state.dart';\nimport '../services/audio_service.dart';",
            1,
        )
        if "audio_service.dart" not in t:
            t = "import '../services/audio_service.dart';\n" + t
    if "meditation_ambient" not in t and "playLoop" not in t.split("initState")[-1][:500] if "initState" in t else True:
        if "void initState()" in t:
            t = re.sub(
                r"(void initState\(\)\s*\{\s*super\.initState\(\);)",
                r"""\1\n    AudioService.instance.playLoop(\n      '%s',\n      volume: 0.26,\n      fadeIn: true,\n    );""" % asset,
                t,
                count=1,
            )
        else:
            t = re.sub(
                r"(class _OnboardingScreenState[^{]*\{)",
                r"""\1\n  @override\n  void initState() {\n    super.initState();\n    AudioService.instance.playLoop(\n      '%s',\n      volume: 0.26,\n      fadeIn: true,\n    );\n  }\n""" % asset,
                t,
                count=1,
            )
    if "fadeOut" not in t and "completeOnboarding" in t:
        t = re.sub(
            r"(await\s+)?(state\.completeOnboarding\([^;]*\);)",
            r"await AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1800));\n    \1\2",
            t,
            count=1,
        )
    if "void dispose()" in t and "AudioService.instance.stop()" not in t:
        t = re.sub(
            r"(void dispose\(\)\s*\{)",
            r"\1\n    try { AudioService.instance.stop(); } catch (_) {}",
            t,
            count=1,
        )
    ob.write_text(t, encoding="utf-8")
    print("Onboarding soundtrack OK")

ais = list(Path("lib/screens").glob("*ai*chat*.dart")) + list(Path("lib/screens").glob("*Ai*Chat*.dart"))
for ai in ais:
    t = ai.read_text(encoding="utf-8")
    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
    t = t.replace("assets/audio/ai_ambient.wav", asset)
    t = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'[^']+'\s*,\s*volume:\s*[0-9.]+\s*\)",
        "AudioService.instance.playLoop('%s', volume: 0.28, fadeIn: true)" % asset,
        t,
    )
    t = t.replace(
        "AudioService.instance.stop()",
        "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
    )
    if "_muted" not in t:
        t = re.sub(
            r"(class _\w+State extends State<[^>]+>\s*\{)",
            r"\1\n  bool _muted = false;\n",
            t,
            count=1,
        )
    if "volume_up_rounded" not in t and "volume_off_rounded" not in t:
        mute = """\n            IconButton(\n              tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',\n              icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 22),\n              onPressed: () async {\n                await AudioService.instance.toggleMute();\n                setState(() => _muted = AudioService.instance.isMuted);\n              },\n            ),\n"""
        if re.search(r"child:\s*Row\(\s*children:\s*\[", t):
            t = re.sub(r"(child:\s*Row\(\s*children:\s*\[)", r"\1" + mute, t, count=1)
        elif "appBar: AppBar(" in t:
            t = re.sub(
                r"(appBar:\s*AppBar\()",
                r"""\1\n        actions: [\n          IconButton(\n            tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',\n            icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),\n            onPressed: () async {\n              await AudioService.instance.toggleMute();\n              setState(() => _muted = AudioService.instance.isMuted);\n            },\n          ),\n        ],\n""",
                t,
                count=1,
            )
    ai.write_text(t, encoding="utf-8")
    print("AI soundtrack OK", ai)

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
        print("pubspec updated")

print("soundtrack_patch done")
