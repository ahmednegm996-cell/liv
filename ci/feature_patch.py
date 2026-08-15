#!/usr/bin/env python3
"""Feature fixes: personalityInsight, AI add actions, goals→أحلام, progress circle size."""
from pathlib import Path
import re

ROOT = Path(".")

PERSONALITY_METHOD = r'''
  Future<String> personalityInsight({required String profileSummary}) {
    return generateText(
      'انت محلل شخصية هادئ وواقعي لتطبيق Liv.\n'
      'بناء على ملخص المستخدم التالي اكتب تحليل شخصية مختصر وواضح بالعامية المصرية (8-12 سطر):\n'
      '- نمط الشخصية العام\n'
      '- نقاط القوة\n'
      '- نقاط تحتاج تحسين\n'
      '- عادة واحدة مقترحة\n'
      '- جملة تحفيزية قصيرة\n\n'
      'الملخص:\n' + profileSummary + '\n\n'
      'لا تستخدم Markdown. كن صادق ومفيد.',
    );
  }
'''

# ---------- 1) Real personalityInsight ----------
gs = ROOT / "lib/services/gemini_service.dart"
if gs.exists():
    t = gs.read_text(encoding="utf-8")
    if "Keep growing with LIV" in t:
        t = re.sub(
            r"Future<String>\s+personalityInsight[\s\S]*?Keep growing with LIV![\s\S]*?\n  \}",
            "",
            t,
        )
    if "personalityInsight" not in t:
        idx = t.rfind("}")
        if idx != -1:
            t = t[:idx] + PERSONALITY_METHOD + t[idx:]
            gs.write_text(t, encoding="utf-8")
            print("personalityInsight: real method added")
    else:
        print("personalityInsight: already present")

    t = gs.read_text(encoding="utf-8")
    if "[ADD_GOOD:" not in t:
        old = "رد بهدوء ووضوح.\n''');"
        new = (
            "رد بهدوء ووضوح.\n"
            "لو المستخدم طلب عادة كويسة او عادة وحشة او مهمة بشكل واضح، اضف في اخر الرد سطر واحد فقط:\n"
            "[ADD_GOOD:اسم العادة] او [ADD_BAD:اسم العادة] او [ADD_TASK:عنوان المهمة]\n"
            "من غير شرح بعد السطر ده.\n''');"
        )
        if old in t:
            t = t.replace(old, new, 1)
            gs.write_text(t, encoding="utf-8")
            print("chat prompt: ADD tags enabled")
        else:
            print("chat prompt: marker not found")

# ---------- 2) AI chat action chips ----------
ai = ROOT / "lib/screens/ai_chat_screen.dart"
if ai.exists():
    t = ai.read_text(encoding="utf-8")
    changed = False

    if "_pendingAction" not in t:
        t = re.sub(
            r"(bool\s+_sending\s*=\s*false;)",
            r"\1\n  Map<String, String>? _pendingAction;",
            t,
            count=1,
        )
        changed = True

    if "_parseAddTag" not in t and "Future<void> _send(" in t:
        helpers = r'''
  Map<String, String>? _parseAddTag(String reply) {
    final m = RegExp(r'\[ADD_(GOOD|BAD|TASK):([^\]]+)\]').firstMatch(reply);
    if (m == null) return null;
    return {'type': m.group(1)!, 'name': m.group(2)!.trim()};
  }

  String _stripAddTag(String reply) {
    return reply.replaceAll(RegExp(r'\s*\[ADD_(GOOD|BAD|TASK):[^\]]+\]\s*'), '').trim();
  }

  Future<void> _applyPendingAction() async {
    final action = _pendingAction;
    if (action == null) return;
    final state = context.read<AppState>();
    final name = action['name'] ?? '';
    if (name.isEmpty) return;
    try {
      final type = action['type'];
      if (type == 'GOOD') {
        await state.addHabit(name, true);
      } else if (type == 'BAD') {
        await state.addHabit(name, false);
      } else if (type == 'TASK') {
        await state.addWeeklyTask(name);
      }
      if (!mounted) return;
      setState(() {
        _pendingAction = null;
        final msg = type == 'TASK'
            ? 'تمت إضافة "$name" إلى المهام.'
            : type == 'BAD'
                ? 'تمت إضافة "$name" إلى العادات السيئة.'
                : 'تمت إضافة "$name" إلى العادات الجيدة.';
        _messages.add({'role': 'assistant', 'text': msg});
      });
      await _persist();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'مقدرناش نضيف العنصر: $e'});
      });
    }
  }

'''
        t = t.replace("Future<void> _send(", helpers + "  Future<void> _send(", 1)
        changed = True

    if "_parseAddTag" in t and "_parseAddTag(reply)" not in t:
        t2 = re.sub(
            r"setState\(\(\)\s*\{\s*_messages\.add\(\{'role':\s*'assistant',\s*'text':\s*reply\}\);\s*_sending\s*=\s*false;\s*\}\);",
            "final action = _parseAddTag(reply);\n"
            "      final clean = _stripAddTag(reply);\n"
            "      setState(() {\n"
            "        _messages.add({'role': 'assistant', 'text': clean.isEmpty ? reply : clean});\n"
            "        _pendingAction = action;\n"
            "        _sending = false;\n"
            "      });",
            t,
            count=1,
        )
        if t2 != t:
            t = t2
            changed = True

    if "_pendingAction" in t and "إضافة إلى العادات" not in t:
        chip = '''
          if (_pendingAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: ActionChip(
                  avatar: const Icon(Icons.add_task, size: 18),
                  label: Text(
                    _pendingAction!['type'] == 'TASK'
                        ? 'إضافة إلى المهام اليومية'
                        : _pendingAction!['type'] == 'BAD'
                            ? 'إضافة إلى العادات السيئة'
                            : 'إضافة إلى العادات الجيدة',
                  ),
                  onPressed: _applyPendingAction,
                ),
              ),
            ),
'''
        if "_quickPrompts()," in t:
            t = t.replace("_quickPrompts(),", "_quickPrompts()," + chip, 1)
            changed = True
        elif "child: _composer" in t:
            t = t.replace("child: _composer", chip + "\n          child: _composer", 1)
            changed = True

    if changed:
        ai.write_text(t, encoding="utf-8")
        print("AI chat: action chips wired")
    else:
        print("AI chat: no structural change")

# ---------- 3) l10n ----------
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
    else:
        print("l10n: skip")

# ---------- 4) Progress circle ----------
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
    else:
        print("home: pattern not found")

print("feature_patch done")
