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

# 2) Gemini: keep ZIP full implementation.
#    Inject ADD_ tags into chat prompt + ensure real personalityInsight exists.
gs = lib / "services/gemini_service.dart"
if gs.exists():
    g = gs.read_text(encoding="utf-8")

    if "Keep growing with LIV" in g:
        g = re.sub(
            r"Future<String>\s+personalityInsight[\s\S]*?Keep growing with LIV![\s\S]*?\n  \}",
            "",
            g,
        )
        g = re.sub(
            r"String\s+personalityInsight\s*\([\s\S]*?Keep going![\s\S]*?\n  \}",
            "",
            g,
        )
        print("Removed Keep growing / Keep going placeholder")

    tag_block = (
        "قواعد ADD الصارمة (مهم جداً):\n"
        "- أضف أسطر ADD في آخر الرد فقط إذا طلب المستخدم بوضوح حفظ/إضافة عنصر محدد.\n"
        "- ممنوع تماماً أي ADD عند التحية أو الشكر أو سؤال عام أو نصيحة أو دردشة.\n"
        "- أمثلة بلا ADD: أهلا / ازاي أنظم يومي؟ / حفزني / نصيحة نوم.\n"
        "- أمثلة مع ADD: عايز أصلي كل يوم / بكرة هذاكر / حلمي أفتح شركة.\n"
        "- لكل عنصر سطر منفصل بالصيغة فقط:\n"
        "[ADD_TASK:عنوان المهمة]\n"
        "[ADD_GOOD:اسم العادة الجيدة]\n"
        "[ADD_BAD:اسم العادة السيئة]\n"
        "[ADD_DREAM:عنوان الحلم]\n"
        "- TASK = شيء محدد قريب/مرة واحدة. GOOD/BAD = عادة متكررة. DREAM = هدف طويل المدى.\n"
        "- لو أكتر من عنصر: سطر ADD منفصل لكل واحد. من غير شرح بعد أسطر الـADD.\n"
    )

    if "قواعد ADD الصارمة" in g:
        print("Strict ADD_ rules already present")
    elif "Future<String> chat(" in g:
        injected = False
        for old in [
            "رد بهدوء ووضوح.\n''');",
            "رد بهدوء ووضوح.\n\"\"\");",
            "رد بهدوء ووضوح.''');",
        ]:
            if old in g:
                g = g.replace(old, "رد بهدوء ووضوح.\n" + tag_block + "''');", 1)
                injected = True
                print("Injected multi-action ADD_ tags into chat prompt")
                break
        if not injected and "رد بهدوء ووضوح." in g:
            g = g.replace("رد بهدوء ووضوح.", "رد بهدوء ووضوح.\n" + tag_block, 1)
            print("Injected multi-action ADD_ tags (fallback)")

    if "personalityInsight" not in g:
        method = (
            "\n"
            "  Future<String> personalityInsight({required String profileSummary}) {\n"
            "    return generateText('''\n"
            "انت محلل شخصية هادئ وواقعي لتطبيق Liv.\n"
            "بناء على ملخص المستخدم التالي اكتب تحليل شخصية مختصر وواضح بالعامية المصرية (8-12 سطر):\n"
            "- نمط الشخصية العام\n"
            "- نقاط القوة\n"
            "- نقاط تحتاج تحسين\n"
            "- عادة واحدة مقترحة\n"
            "- جملة تحفيزية قصيرة\n"
            "\n"
            "الملخص:\n"
            "$profileSummary\n"
            "\n"
            "لا تستخدم Markdown. كن صادق ومفيد.\n"
            "''');\n"
            "  }\n"
        )
        last = g.rstrip()
        if last.endswith("}"):
            g = last[:-1] + method + "}\n"
            print("Injected real personalityInsight method")
        else:
            g = g + method
            print("Appended personalityInsight method")
    else:
        print("personalityInsight present")

    gs.write_text(g, encoding="utf-8")

    final = gs.read_text(encoding="utf-8")
    if "personalityInsight" not in final:
        raise SystemExit("ERROR: personalityInsight still missing after inject")
    if "Keep growing with LIV" in final or "Keep going!" in final:
        raise SystemExit("ERROR: placeholder still present")
    if "Liv.\n'" in final or "سطر):\n'" in final:
        raise SystemExit("ERROR: broken string literals detected in gemini_service.dart")
    print("gemini_service.dart OK")

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

# 4) home circle — robust size bump on the real progress ring
home = lib / "screens/home_screen.dart"
if home.exists():
    ht = home.read_text(encoding="utf-8")
    pat = re.compile(
        r"(SizedBox\(\n\s*width:\s*)(\d+)(,\n\s*height:\s*)(\d+)"
        r"(,\n\s*child:\s*Stack\(\n\s*alignment:\s*Alignment\.center,\n\s*children:\s*\[\n\s*"
        r"CircularProgressIndicator\(\n\s*value:\s*progress,\n\s*strokeWidth:\s*)([\d.]+)",
        re.M,
    )
    m = pat.search(ht)
    if m:
        ht2 = pat.sub(r"\g<1>96\g<3>96\g<5>7.5", ht, count=1)
        if ht2 != ht:
            home.write_text(ht2, encoding="utf-8")
            print(f"home: circle {m.group(2)}→96 stroke {m.group(6)}→7.5")
        else:
            print("home: circle already 96")
    else:
        if "width: 70," in ht and "value: progress" in ht:
            ht = ht.replace("width: 70,", "width: 96,", 1).replace("height: 70,", "height: 96,", 1)
            ht = ht.replace("strokeWidth: 6,", "strokeWidth: 7.5,", 1)
            home.write_text(ht, encoding="utf-8")
            print("home: circle fallback 70→96")
        else:
            print("WARNING: home progress circle pattern not found")

print("feature_patch done OK")
