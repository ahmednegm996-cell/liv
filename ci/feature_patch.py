#!/usr/bin/env python3
"""Apply AI features that survive ZIP restore."""
from pathlib import Path
import runpy
import re

ROOT = Path(".")
ci = ROOT / "ci"

# Write full AI sources over ZIP copies
for script in ("write_gemini_overlay.py", "write_ai_overlay.py"):
    p = ci / script
    if p.exists():
        runpy.run_path(str(p))
    else:
        print(f"WARNING: missing {p}")

# l10n goals → أحلام
l10n = ROOT / "lib/services/l10n.dart"
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
        print(f"l10n: {n} replacements")

# Progress circle
home = ROOT / "lib/screens/home_screen.dart"
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

# Final hard check
g = (ROOT / "lib/services/gemini_service.dart").read_text(encoding="utf-8")
if "Keep growing with LIV" in g:
    raise SystemExit("ERROR: Keep growing placeholder still present")
if "personalityInsight" not in g:
    raise SystemExit("ERROR: personalityInsight missing")
ai = (ROOT / "lib/screens/ai_chat_screen.dart").read_text(encoding="utf-8")
if "_pendingAction" not in ai or "addHabit" not in ai:
    raise SystemExit("ERROR: AI actions missing")
print("feature_patch done OK")
