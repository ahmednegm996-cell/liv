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

# 4) home progress circle — MUST be clearly larger so % is readable on device.
# Direct SizedBox size (no OverflowBox). 130px ~1.85x original 70.
TARGET_W = 130
TARGET_STROKE = 12
TARGET_FONT = 18

home = lib / "screens/home_screen.dart"
if not home.exists():
    raise SystemExit("ERROR: lib/screens/home_screen.dart missing after ZIP restore")

ht = home.read_text(encoding="utf-8")

# Drop failed OverflowBox experiments
if "OverflowBox" in ht:
    ht = re.sub(
        r"SizedBox\(\s*width:\s*\d+\s*,\s*height:\s*\d+\s*,\s*child:\s*OverflowBox\([\s\S]*?"
        r"child:\s*SizedBox\(\s*width:\s*\d+\s*,\s*height:\s*\d+\s*,\s*child:\s*Stack\(",
        f"SizedBox(\n                    width: {TARGET_W},\n                    height: {TARGET_W},\n                    child: Stack(",
        ht,
        count=1,
    )
    ht = ht.replace("\n          clipBehavior: Clip.none,", "", 1)
    # remove extra closing parens from OverflowBox/SizedBox if left over — handled below by full block replace
    print("home: stripped OverflowBox wrapper")

# Progress card padding 16→10 to keep overall card from exploding
old_card = (
    "            // Progress (من الصورة)\n"
    "            SectionCard(\n"
    "              padding: const EdgeInsets.all(16),\n"
    "              child: Row("
)
new_card = (
    "            // Progress (من الصورة)\n"
    "            SectionCard(\n"
    "              padding: const EdgeInsets.all(10),\n"
    "              child: Row("
)
if old_card in ht:
    ht = ht.replace(old_card, new_card, 1)
    print("home: progress SectionCard padding 16→10")
else:
    ht2 = re.sub(
        r"(// Progress[\s\S]{0,80}?SectionCard\(\s*padding:\s*const EdgeInsets\.all\()(\d+)(\))",
        r"\g<1>10\3",
        ht,
        count=1,
    )
    if ht2 != ht:
        ht = ht2
        print("home: progress SectionCard padding →10 (regex)")

# Robust: any SizedBox wrapping CircularProgressIndicator(value: progress)
pat = re.compile(
    r"(SizedBox\(\s*width:\s*)(\d+)(\s*,\s*height:\s*)(\d+)(\s*,\s*child:\s*Stack\(\s*"
    r"alignment:\s*Alignment\.center\s*,\s*children:\s*\[\s*"
    r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*)([\d.]+)",
    re.M,
)
m = pat.search(ht)
if not m:
    raise SystemExit(
        "ERROR: progress CircularProgressIndicator + SizedBox pattern not found in home_screen.dart"
    )

old_w, old_s = m.group(2), m.group(6)
ht = pat.sub(
    rf"\g<1>{TARGET_W}\g<3>{TARGET_W}\g<5>{TARGET_STROKE}",
    ht,
    count=1,
)
print(f"home: circle {old_w}→{TARGET_W} stroke {old_s}→{TARGET_STROKE}")

# Percent label next to this indicator only — make readable
# Match the Text right after value: progress indicator
ht2, nfont = re.subn(
    r"(\$\{\(progress \* 100\)\.round\(\)\}%[\s\S]{0,120}?fontSize:\s*)(\d+)",
    rf"\g<1>{TARGET_FONT}",
    ht,
    count=1,
)
if nfont:
    ht = ht2
    print(f"home: percent fontSize → {TARGET_FONT}")
else:
    # fallback exact
    for old_fs in ("fontSize: 14,", "fontSize: 16,", "fontSize: 20,"):
        # only replace near progress percent
        idx = ht.find("${(progress * 100).round()}%")
        if idx < 0:
            break
        window = ht[idx:idx + 220]
        if old_fs in window:
            ht = ht[:idx] + window.replace(old_fs, f"fontSize: {TARGET_FONT},", 1) + ht[idx + 220:]
            print(f"home: percent fontSize {old_fs} → {TARGET_FONT}")
            break

home.write_text(ht, encoding="utf-8")
final = home.read_text(encoding="utf-8")
if f"width: {TARGET_W}" not in final:
    raise SystemExit(f"ERROR: width {TARGET_W} not in final home_screen")
if "OverflowBox" in final:
    raise SystemExit("ERROR: OverflowBox still in home_screen")
# dump snippet for Actions log
idx = final.find("value: progress")
print("--- circle snippet ---")
print(final[max(0, idx - 180): idx + 220])
print("--- end snippet ---")
print(f"VERIFY OK: circle={TARGET_W} stroke={TARGET_STROKE} font={TARGET_FONT}")

print("feature_patch done OK")
