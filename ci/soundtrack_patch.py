#!/usr/bin/env python3
"""Wire meditation ambient soundtrack into onboarding + AI chat with fade & mute."""
from pathlib import Path
import re

# ---------- Ensure AudioService has fade/mute (prefer committed version) ----------
audio = Path("lib/services/audio_service.dart")
if audio.exists():
    t = audio.read_text(encoding="utf-8")
    if "fadeOut" not in t or "toggleMute" not in t:
        print("WARNING: AudioService missing fade/mute")
    else:
        print("AudioService OK (fade/mute present)")

# ---------- Decode meditation asset from ci base64 parts ----------
parts = sorted(Path("ci").glob("meditation.b64.p*"))
if parts:
    b64 = "".join(p.read_text(encoding="utf-8").strip() for p in parts)
    import base64
    out = Path("assets/audio/meditation_ambient.mp3")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(b64))
    print("Wrote", out, out.stat().st_size, "bytes")
else:
    print("WARNING: no meditation.b64.p* parts")

# ---------- Onboarding: start on init, fade out on complete ----------
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

    if "meditation_ambient" not in t:
        if "void initState()" in t:
            t = re.sub(
                r"(void initState\(\)\s*\{[^\}]*super\.initState\(\);)",
                r"""\1
    // Calm meditation soundtrack during onboarding questions
    AudioService.instance.playLoop(
      'assets/audio/meditation_ambient.mp3',
      volume: 0.26,
      fadeIn: true,
    );""",
                t,
                count=1,
            )
            changed = True
        else:
            insert = """
  @override
  void initState() {
    super.initState();
    AudioService.instance.playLoop(
      'assets/audio/meditation_ambient.mp3',
      volume: 0.26,
      fadeIn: true,
    );
  }
"""
            t = re.sub(
                r"(class _OnboardingScreenState[^{]*\{)",
                r"\1" + insert,
                t,
                count=1,
            )
            changed = True

    if "fadeOut" not in t and "completeOnboarding" in t:
        t = re.sub(
            r"(await\s+)?(state\.completeOnboarding\([^;]*\);)",
            r"""await AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1800));
    \1\2""",
            t,
            count=1,
        )
        changed = True

    if "void dispose()" in t and "AudioService.instance.stop()" not in t and "fadeOut" not in t.split("dispose")[1][:400]:
        t = re.sub(
            r"(void dispose\(\)\s*\{)",
            r"""\1
    AudioService.instance.stop();""",
            t,
            count=1,
        )
        changed = True

    if changed:
        ob.write_text(t, encoding="utf-8")
        print("Onboarding soundtrack wired")
    else:
        print("Onboarding already has soundtrack hooks")
else:
    print("WARNING: onboarding_screen.dart missing")

# ---------- AI Chat: replace ambient + mute button ----------
ai_candidates = list(Path("lib/screens").glob("*ai*chat*.dart")) + list(Path("lib/screens").glob("*Ai*Chat*.dart"))
ai = ai_candidates[0] if ai_candidates else Path("lib/screens/ai_chat_screen.dart")

if ai.exists():
    t = ai.read_text(encoding="utf-8")
    changed = False

    if "audio_service.dart" not in t:
        t = "import '../services/audio_service.dart';\n" + t
        changed = True

    if "ai_ambient.wav" in t:
        t = t.replace("assets/audio/ai_ambient.wav", "assets/audio/meditation_ambient.mp3")
        changed = True

    t2 = re.sub(
        r"AudioService\.instance\.playLoop\(\s*'assets/audio/meditation_ambient\.mp3'\s*,\s*volume:\s*[0-9.]+\s*\)",
        "AudioService.instance.playLoop('assets/audio/meditation_ambient.mp3', volume: 0.28, fadeIn: true)",
        t,
    )
    if t2 != t:
        t = t2
        changed = True

    if "meditation_ambient" not in t:
        if "void initState()" in t:
            t = re.sub(
                r"(void initState\(\)\s*\{[^\}]*super\.initState\(\);)",
                r"""\1
    if (widget.active) {
      AudioService.instance.playLoop(
        'assets/audio/meditation_ambient.mp3',
        volume: 0.28,
        fadeIn: true,
      );
    }""",
                t,
                count=1,
            )
            changed = True

    # Prefer soft fade when leaving AI
    t = t.replace(
        "AudioService.instance.stop()",
        "AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200))",
    )

    if "_muted" not in t:
        t = re.sub(
            r"(class _\w+State extends State<[^>]+>\s*\{)",
            r"""\1
  bool _muted = false;
""",
            t,
            count=1,
        )
        changed = True

    if "volume_up_rounded" not in t and "volume_off_rounded" not in t:
        mute_snippet = """
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
        # Prefer header row
        if re.search(r"Widget _header\([^"]*\)[^{]*\{[\s\S]*?child:\s*Row\(\s*children:\s*\[", t):
            t = re.sub(
                r"(Widget _header\([^)]*\)[^{]*\{[\s\S]*?child:\s*Row\(\s*children:\s*\[)",
                r"\1" + mute_snippet,
                t,
                count=1,
            )
            changed = True
        elif "appBar: AppBar(" in t:
            t = re.sub(
                r"(appBar:\s*AppBar\([^)]*title:[^,]+,)",
                r"""\1
        actions: [
          IconButton(
            tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
            icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
            onPressed: () async {
              await AudioService.instance.toggleMute();
              setState(() => _muted = AudioService.instance.isMuted);
            },
          ),
        ],
""",
                t,
                count=1,
            )
            changed = True
        elif "body: Stack(" in t:
            mute_pos = """
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: Material(
                color: Colors.black.withOpacity(0.35),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () async {
                    await AudioService.instance.toggleMute();
                    setState(() => _muted = AudioService.instance.isMuted);
                  },
                ),
              ),
            ),
"""
            t = re.sub(
                r"(body:\s*Stack\(\s*children:\s*\[)",
                r"\1" + mute_pos,
                t,
                count=1,
            )
            changed = True

    if changed or "meditation_ambient" in t:
        ai.write_text(t, encoding="utf-8")
        print("AI chat soundtrack + mute wired:", ai)
    else:
        print("AI chat structure unexpected")
else:
    print("WARNING: ai chat screen missing")

print("soundtrack_patch done")
