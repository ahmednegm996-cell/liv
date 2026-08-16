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

# 4) home progress ring — REAL layout size (OverflowBox was clipped/invisible on device).
# Card padding for this SectionCard only 16→12 to offset height. % fontSize stays 14.
home = lib / "screens/home_screen.dart"
if not home.exists():
    raise SystemExit("ERROR: lib/screens/home_screen.dart missing after ZIP restore")

ht = home.read_text(encoding="utf-8")

# Remove prior OverflowBox / Clip.none experiments if present
if "OverflowBox" in ht:
    ht = ht.replace("\n          clipBehavior: Clip.none,", "", 1)
    print("home: removed prior OverflowBox/Clip.none experiment")

old_card = """            // Progress (من الصورة)
            SectionCard(
              padding: const EdgeInsets.all(16),
              child: Row("""
new_card = """            // Progress (من الصورة)
            SectionCard(
              padding: const EdgeInsets.all(12),
              child: Row("""
if old_card in ht:
    ht = ht.replace(old_card, new_card, 1)
    print("home: progress SectionCard padding 16→12")
elif "padding: const EdgeInsets.all(12)" in ht and "// Progress" in ht:
    print("home: progress SectionCard padding already 12")
else:
    print("home: NOTE progress card padding pattern soft-skip")

def circle_block(w, stroke):
    return (
        f"""                  SizedBox(
                    width: {w},
                    height: {w},
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: {stroke},
                          backgroundColor: accent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                        Text(
                          '${{(progress * 100).round()}}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: accent),
                        ),
                      ],
                    ),
                  ),"""
    )

TARGET = 100
TARGET_STROKE = 10
NEW = circle_block(TARGET, TARGET_STROKE)

OLD_OVERFLOW = """                  SizedBox(
                    width: 70,
                    height: 70,
                    child: OverflowBox(
                      maxWidth: 124,
                      maxHeight: 124,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 124,
                        height: 124,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 9,
                              backgroundColor: accent.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),"""

OLD_70 = circle_block(70, 6)
OLD_130 = circle_block(130, 10)

replaced = False
for name, old in [("overflow124", OLD_OVERFLOW), ("70", OLD_70), ("130", OLD_130)]:
    if old in ht:
        ht = ht.replace(old, NEW, 1)
        print(f"home: circle {name} → {TARGET}px stroke {TARGET_STROKE}, fontSize 14")
        replaced = True
        break

if not replaced:
    if f"width: {TARGET}" in ht and "value: progress" in ht and "OverflowBox" not in ht:
        print("home: circle already", TARGET)
        replaced = True
    else:
        raise SystemExit("ERROR: progress circle block not found to resize")

home.write_text(ht, encoding="utf-8")
final = home.read_text(encoding="utf-8")
if f"width: {TARGET}" not in final or "value: progress" not in final:
    raise SystemExit(f"ERROR: verify failed width {TARGET}")
if "OverflowBox" in final:
    raise SystemExit("ERROR: OverflowBox still present — remove it")
idx = final.find("${(progress * 100).round()}%")
snippet = final[idx:idx + 200] if idx >= 0 else ""
if "fontSize: 20" in snippet:
    raise SystemExit("ERROR: percent fontSize enlarged")
print(f"VERIFY OK: circle layout={TARGET} stroke={TARGET_STROKE} fontSize=14 no OverflowBox")

print("feature_patch done OK")
