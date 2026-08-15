#!/usr/bin/env python3
"""Apply AI features that survive ZIP restore."""
from pathlib import Path
import runpy
import shutil

ROOT = Path(".")
ci = ROOT / "ci"
exp = ci / "expand_ai_overlay.py"
if exp.exists():
    runpy.run_path(str(exp))

overlay = ROOT / "ci/overlays/lib"
lib = ROOT / "lib"
for rel, marker in [
    ("services/gemini_service.dart", "personalityInsight"),
    ("screens/ai_chat_screen.dart", "addHabit"),
]:
    src = overlay / rel
    if not src.exists() or src.stat().st_size < 100:
        raise SystemExit(f"ERROR: missing/empty overlay {src}")
    text = src.read_text(encoding="utf-8")
    if marker not in text:
        raise SystemExit(f"ERROR: overlay {src} missing {marker}")
    if "Keep growing with LIV" in text:
        raise SystemExit(f"ERROR: placeholder in {src}")
    dest = lib / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    print(f"feature_patch: applied {rel}")

l10n = lib / "services/l10n.dart"
if l10n.exists():
    t = l10n.read_text(encoding="utf-8")
    reps = [
        ("'dreams': 'أهداف'", "'dreams': 'أحلام'"),
        ("'dreams': 'الأهداف'", "'dreams': 'الأحلام'"),
        ("'add_dream': 'هدف جديد'", "'add_dream': 'حلم جديد'"),
        ("'no_dreams': 'لسه معملتش أهداف'", "'no_dreams': 'لسه معملتش أحلام'"),
        ("'no_dreams': 'لا توجد أهداف بعد'", "'no_dreams': 'لا توجد أحلام بعد'"),
        ("'goals': 'أهدافك دلوقتي؟'", "'goals': 'أحلامك دلوقتي؟'"),
        ("'goals': 'أهدافك الحالية؟'", "'goals': 'أحلامك الحالية؟'"),
    ]
    n = 0
    for a, b in reps:
        if a in t:
            t = t.replace(a, b)
            n += 1
    if n:
        l10n.write_text(t, encoding="utf-8")
        print(f"l10n: {n}")

home = lib / "screens/home_screen.dart"
if home.exists():
    t = home.read_text(encoding="utf-8")
    old = """                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,"""
    new = """                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6.5,"""
    if old in t:
        home.write_text(t.replace(old, new, 1), encoding="utf-8")
        print("home: circle 70→80")

print("feature_patch done OK")
