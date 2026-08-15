#!/usr/bin/env python3
"""Apply AI features that survive ZIP restore."""
from pathlib import Path
import runpy
import shutil
import re

ROOT = Path(".")
ci = ROOT / "ci"
exp = ci / "expand_ai_overlay.py"
if exp.exists():
    try:
        runpy.run_path(str(exp))
    except Exception as e:
        print(f"expand soft-fail: {e}")

overlay = ROOT / "ci/overlays/lib"
lib = ROOT / "lib"

# 1) AI chat screen (action chips) — full overlay
rel = "screens/ai_chat_screen.dart"
src = overlay / rel
if src.exists() and src.stat().st_size > 500 and "addHabit" in src.read_text(encoding="utf-8"):
    dest = lib / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    print(f"feature_patch: applied {rel}")
else:
    print(f"WARNING: ai_chat overlay missing or incomplete — {src}")

# 2) Gemini: keep ZIP full implementation (all methods + real personalityInsight).
#    Only inject the ADD_ tag instruction into the chat prompt if missing.
gs = lib / "services/gemini_service.dart"
if gs.exists():
    g = gs.read_text(encoding="utf-8")
    if "Keep growing with LIV" in g:
        g = re.sub(
            r"Future<String>\s+personalityInsight[\s\S]*?Keep growing with LIV![\s\S]*?\n  \}",
            "",
            g,
        )
        print("Removed Keep growing placeholder")
    if "ADD_GOOD" not in g and "Future<String> chat(" in g:
        tag_block = (
            "لو المستخدم طلب عادة كويسة او عادة وحشة او مهمة بشكل واضح، اضف في اخر الرد سطر واحد فقط بالصيغة:\n"
            "[ADD_GOOD:اسم العادة]\n"
            "او\n"
            "[ADD_BAD:اسم العادة]\n"
            "او\n"
            "[ADD_TASK:عنوان المهمة]\n"
            "من غير شرح بعد السطر ده.\n"
        )
        injected = False
        # Common ZIP ending of the chat prompt string
        for old in [
            "رد بهدوء ووضوح.\n''');",
            "رد بهدوء ووضوح.\n\"\"\");",
            "رد بهدوء ووضوح.''');",
            "رد بهدوء ووضوح.",
        ]:
            if old in g:
                g = g.replace(old, "رد بهدوء ووضوح.\n" + tag_block + ("''');" if old.endswith("''');") else ""), 1)
                injected = True
                print(f"Injected ADD_ tags into chat prompt (matched: {old[:20]}...)")
                break
        if not injected:
            # last resort: append before the closing of chat method
            m = re.search(r"(Future<String>\s+chat\([\s\S]*?return generateText\(['\"]{1,3})([\s\S]*?)(['\"]{1,3}\);)", g)
            if m:
                g = g[:m.end(2)] + "\n" + tag_block + g[m.end(2):]
                print("Injected ADD_ tags via regex")
            else:
                print("WARNING: could not locate chat prompt to inject ADD_ tags")
    if "personalityInsight" not in g:
        print("WARNING: personalityInsight still missing")
    else:
        print("personalityInsight present")
    gs.write_text(g, encoding="utf-8")

# 3) l10n dreams -> أحلام
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

# 4) home circle
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
