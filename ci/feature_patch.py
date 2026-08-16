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

# 4) Today-progress CIRCLE — exact block replace from ZIP.
# Bigger outer size (150) + thinner stroke (8) so % text has clear room inside and does not overlap the ring.
TARGET_W = 150
TARGET_STROKE = 8
TARGET_FONT = 16

home = lib / "screens/home_screen.dart"
if not home.exists():
    raise SystemExit("ERROR: lib/screens/home_screen.dart missing after ZIP restore")

ht = home.read_text(encoding="utf-8")

# Exact original ZIP block (the only reliable match)
OLD = (
    "                  SizedBox(\n"
    "                    width: 70,\n"
    "                    height: 70,\n"
    "                    child: Stack(\n"
    "                      alignment: Alignment.center,\n"
    "                      children: [\n"
    "                        CircularProgressIndicator(\n"
    "                          value: progress,\n"
    "                          strokeWidth: 6,\n"
    "                          backgroundColor: accent.withOpacity(0.15),\n"
    "                          valueColor: AlwaysStoppedAnimation(accent),\n"
    "                        ),\n"
    "                        Text(\n"
    "                          '${(progress * 100).round()}%',\n"
    "                          style: TextStyle(\n"
    "                              fontWeight: FontWeight.w900,\n"
    "                              fontSize: 14,\n"
    "                              color: accent),\n"
    "                        ),\n"
    "                      ],\n"
    "                    ),\n"
    "                  ),"
)

NEW = (
    f"                  SizedBox(\n"
    f"                    width: {TARGET_W},\n"
    f"                    height: {TARGET_W},\n"
    f"                    child: Stack(\n"
    f"                      alignment: Alignment.center,\n"
    f"                      children: [\n"
    f"                        CircularProgressIndicator(\n"
    f"                          value: progress,\n"
    f"                          strokeWidth: {TARGET_STROKE},\n"
    f"                          backgroundColor: accent.withOpacity(0.15),\n"
    f"                          valueColor: AlwaysStoppedAnimation(accent),\n"
    f"                        ),\n"
    f"                        Text(\n"
    f"                          '${{(progress * 100).round()}}%',\n"
    f"                          style: TextStyle(\n"
    f"                              fontWeight: FontWeight.w900,\n"
    f"                              fontSize: {TARGET_FONT},\n"
    f"                              color: accent),\n"
    f"                        ),\n"
    f"                      ],\n"
    f"                    ),\n"
    f"                  ),"
)

# Also match prior partial patches (100/130 + various fonts/strokes)
def block(w, stroke, font):
    return (
        f"                  SizedBox(\n"
        f"                    width: {w},\n"
        f"                    height: {w},\n"
        f"                    child: Stack(\n"
        f"                      alignment: Alignment.center,\n"
        f"                      children: [\n"
        f"                        CircularProgressIndicator(\n"
        f"                          value: progress,\n"
        f"                          strokeWidth: {stroke},\n"
        f"                          backgroundColor: accent.withOpacity(0.15),\n"
        f"                          valueColor: AlwaysStoppedAnimation(accent),\n"
        f"                        ),\n"
        f"                        Text(\n"
        f"                          '${{(progress * 100).round()}}%',\n"
        f"                          style: TextStyle(\n"
        f"                              fontWeight: FontWeight.w900,\n"
        f"                              fontSize: {font},\n"
        f"                              color: accent),\n"
        f"                        ),\n"
        f"                      ],\n"
        f"                    ),\n"
        f"                  ),"
    )

replaced = False
for name, old in [
    ("zip70", OLD),
    ("100/10/14", block(100, 10, 14)),
    ("100/10/18", block(100, 10, 18)),
    ("130/12/18", block(130, 12, 18)),
    ("130/12/14", block(130, 12, 14)),
    ("130/10/18", block(130, 10, 18)),
]:
    if old in ht:
        ht = ht.replace(old, NEW, 1)
        print(f"home: replaced circle block ({name}) → {TARGET_W}px stroke {TARGET_STROKE} font {TARGET_FONT}")
        replaced = True
        break

if not replaced:
    # Last resort: force width/height/stroke/font via targeted regex on progress ring only
    pat = re.compile(
        r"(SizedBox\(\s*width:\s*)(\d+)(\s*,\s*height:\s*)(\d+)(\s*,\s*child:\s*Stack\(\s*"
        r"alignment:\s*Alignment\.center\s*,\s*children:\s*\[\s*"
        r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*)([\d.]+)",
        re.M,
    )
    m = pat.search(ht)
    if not m:
        raise SystemExit("ERROR: progress circle SizedBox not found")
    ht = pat.sub(rf"\g<1>{TARGET_W}\g<3>{TARGET_W}\g<5>{TARGET_STROKE}", ht, count=1)
    idx = ht.find("${(progress * 100).round()}%")
    if idx >= 0:
        win = ht[idx:idx + 220]
        win2 = re.sub(r"fontSize:\s*\d+", f"fontSize: {TARGET_FONT}", win, count=1)
        ht = ht[:idx] + win2 + ht[idx + 220:]
    print(f"home: regex forced circle → {TARGET_W}/{TARGET_STROKE}/{TARGET_FONT}")
    replaced = True

# Progress card padding slightly tighter
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
    print("home: progress card padding 16→10")

home.write_text(ht, encoding="utf-8")
final = home.read_text(encoding="utf-8")

if f"width: {TARGET_W}" not in final or f"height: {TARGET_W}" not in final:
    raise SystemExit(f"ERROR: circle size {TARGET_W} missing after patch")
if f"strokeWidth: {TARGET_STROKE}" not in final:
    raise SystemExit(f"ERROR: strokeWidth {TARGET_STROKE} missing")

# Prove the CircularProgressIndicator(value: progress) sits in the 150 box
i = final.find("CircularProgressIndicator(\n                          value: progress")
if i < 0:
    i = final.find("value: progress")
snippet = final[max(0, i - 200): i + 280]
print("--- FINAL CIRCLE SNIPPET ---")
print(snippet)
print("--- END ---")
if f"width: {TARGET_W}" not in snippet and f"width: {TARGET_W}" not in final[max(0,i-250):i]:
    # width should appear just above the indicator
    head = final[max(0, i - 250): i]
    if f"width: {TARGET_W}" not in head:
        raise SystemExit("ERROR: width 150 not adjacent to progress CircularProgressIndicator")

print(f"VERIFY OK: circle={TARGET_W} stroke={TARGET_STROKE} font={TARGET_FONT}")
print("feature_patch done OK")
