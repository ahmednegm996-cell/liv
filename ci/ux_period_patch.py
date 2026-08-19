from pathlib import Path

# ========== 1) models.dart: trackPeriod field ==========
mp = Path("lib/models.dart")
if mp.exists():
    m = mp.read_text(encoding="utf-8")
    if "trackPeriod" not in m:
        m = m.replace(
            "  String gender; // male | female | ''\n  bool hasOnboarded;",
            "  String gender; // male | female | ''\n  bool trackPeriod;\n  bool hasOnboarded;",
            1,
        )
        m = m.replace(
            "    this.gender = '',\n    this.hasOnboarded = false,",
            "    this.gender = '',\n    this.trackPeriod = false,\n    this.hasOnboarded = false,",
            1,
        )
        m = m.replace(
            "        'gender': gender,\n        'hasOnboarded': hasOnboarded,",
            "        'gender': gender,\n        'trackPeriod': trackPeriod,\n        'hasOnboarded': hasOnboarded,",
            1,
        )
        m = m.replace(
            "        gender: j['gender'] ?? '',\n        hasOnboarded: j['hasOnboarded'] ?? false,",
            "        gender: j['gender'] ?? '',\n        trackPeriod: j['trackPeriod'] ?? false,\n        hasOnboarded: j['hasOnboarded'] ?? false,",
            1,
        )
        mp.write_text(m, encoding="utf-8")
        print("models: trackPeriod added")
    else:
        print("models: trackPeriod already present")

# ========== 2) onboarding_screen.dart ==========
p = Path("lib/screens/onboarding_screen.dart")
t = p.read_text(encoding="utf-8")

# --- Gender colors ---
t = t.replace("Color(0xFFB8956A)", "Color(0xFF7DD3FC)")
t = t.replace("Color(0xFFEC4899)", "Color(0xFFF9A8D4)")
t = t.replace("Color(0xFFFBBF24)", "Color(0xFF7DD3FC)")
t = t.replace("Color(0xFFEF4444)", "Color(0xFFF9A8D4)")
t = t.replace("Color(0xFFFFD54F)", "Color(0xFF7DD3FC)")
t = t.replace("Color(0xFFE53935)", "Color(0xFFF9A8D4)")
t = t.replace(
    "color: selected ? accent : Colors.transparent,",
    "color: selected ? AppColors.primary : accent,",
)
t = t.replace(
    "color: selected ? accent.withOpacity(0.22) : Theme.of(context).cardColor,",
    "color: selected ? AppColors.primary.withOpacity(0.18) : accent.withOpacity(0.12),",
)
t = t.replace(
    "color: selected ? accent : secondaryText(context),",
    "color: selected ? AppColors.primary : accent,",
)
t = t.replace(
    "color: selected ? accent : null,",
    "color: selected ? AppColors.primary : accent,",
)

# --- Period tracking state fields ---
if "_trackPeriod" not in t:
    t = t.replace(
        "  String? _gender;\n",
        "  String? _gender;\n  bool _trackPeriod = false;\n  final Set<String> _periodOpts = {};\n",
        1,
    )

if "periodOptionsEg" not in t:
    t = t.replace(
        "  static const goodHabitsEg = [",
        "  static const periodOptionsEg = [\n"
        "    '\u062a\u0630\u0643\u064a\u0631 \u0628\u0645\u0648\u0639\u062f \u0627\u0644\u062f\u0648\u0631\u0629',\n"
        "    '\u062a\u062a\u0628\u0639 \u0627\u0644\u0623\u0639\u0631\u0627\u0636',\n"
        "    '\u062a\u062a\u0628\u0639 \u0627\u0644\u0645\u0632\u0627\u062c',\n"
        "    '\u062a\u062a\u0628\u0639 \u0627\u0644\u0623\u0644\u0645',\n"
        "  ];\n"
        "  static const goodHabitsEg = [",
        1,
    )

# --- Age picker Apple-like ---
if "_tickAgeItem" not in t or "useMagnifier" not in t:
    if "late final FixedExtentScrollController _ageCtrl" not in t:
        t = t.replace(
            "  int _age = 22;\n",
            "  int _age = 22;\n  late final FixedExtentScrollController _ageCtrl;\n",
            1,
        )
    if "_ageCtrl = FixedExtentScrollController" not in t:
        t = t.replace(
            "  void initState() {\n    super.initState();\n    _analyzeCtrl",
            "  void initState() {\n    super.initState();\n    _ageCtrl = FixedExtentScrollController(initialItem: (_age - 12).clamp(0, 68));\n    _analyzeCtrl",
            1,
        )
    if "_ageCtrl.dispose()" not in t:
        t = t.replace(
            "    _page.dispose();\n",
            "    _page.dispose();\n    try { _ageCtrl.dispose(); } catch (_) {}\n",
            1,
        )
    if "void _tickAgeItem()" not in t:
        t = t.replace(
            "  Future<void> _tick() async {",
            "  void _tickAgeItem() {\n"
            "    // Same native path as Sleep Counter (SoundPool tick + haptic)\n"
            "    AudioService.instance.tick();\n"
            "  }\n\n"
            "  Future<void> _tick() async {",
            1,
        )
    if "FixedExtentScrollController(initialItem: _age - 12)" in t:
        t = t.replace(
            "FixedExtentScrollController(initialItem: _age - 12)",
            "_ageCtrl",
        )
    old_cb = (
        "onSelectedItemChanged: (i) async {\n"
        "                  await _tick();\n"
        "                  setState(() => _age = i + 12);\n"
        "                },"
    )
    new_cb = (
        "onSelectedItemChanged: (i) {\n"
        "                  final next = i + 12;\n"
        "                  if (next == _age) return;\n"
        "                  setState(() => _age = next);\n"
        "                  _tickAgeItem();\n"
        "                },"
    )
    if old_cb in t:
        t = t.replace(old_cb, new_cb)
    if "itemExtent: 40," in t and "useMagnifier" not in t:
        t = t.replace(
            "itemExtent: 40,",
            "itemExtent: 44,\n"
            "                diameterRatio: 1.2,\n"
            "                squeeze: 1.05,\n"
            "                useMagnifier: true,\n"
            "                magnification: 1.28,",
            1,
        )

# --- Gender card: clear period when male selected ---
old_tap = (
    "      onTap: () async {\n"
    "        await _tick();\n"
    "        setState(() => _gender = value);\n"
    "      },"
)
new_tap = (
    "      onTap: () async {\n"
    "        await _tick();\n"
    "        setState(() {\n"
    "          _gender = value;\n"
    "          if (value != 'female') {\n"
    "            _trackPeriod = false;\n"
    "            _periodOpts.clear();\n"
    "          }\n"
    "        });\n"
    "      },"
)
if old_tap in t:
    t = t.replace(old_tap, new_tap)

# --- Inject period section method + call ---
if "_periodSection" not in t:
    period_method = """
  Widget _periodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gaps.h20,
        Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: Color(0xFFF9A8D4), size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '\u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u062f\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064a\u0629',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        Gaps.h6,
        Text(
          '\u0627\u062e\u062a\u064a\u0627\u0631\u064a \u2014 \u062a\u0642\u062f\u0631\u064a \u062a\u0641\u0639\u0651\u0644\u064a \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629 \u062f\u0644\u0648\u0642\u062a\u064a',
          style: TextStyle(color: secondaryText(context), fontSize: 13),
        ),
        Gaps.h12,
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '\u062a\u0641\u0639\u064a\u0644 \u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u0628\u0631\u064a\u0648\u062f',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              _trackPeriod
                  ? '\u0647\u0646\u062a\u0627\u0628\u0639 \u0645\u0639\u0627\u0643\u064a \u0627\u0644\u062f\u0648\u0631\u0629 \u0648\u0627\u0644\u0623\u0639\u0631\u0627\u0636'
                  : '\u0627\u0636\u063a\u0637\u064a \u0644\u0644\u062a\u0641\u0639\u064a\u0644',
              style: TextStyle(fontSize: 12, color: secondaryText(context)),
            ),
            value: _trackPeriod,
            activeColor: AppColors.primary,
            onChanged: (v) async {
              await _tick();
              setState(() {
                _trackPeriod = v;
                if (!v) _periodOpts.clear();
              });
            },
          ),
        ),
        if (_trackPeriod) ...[
          Gaps.h12,
          Text(
            '\u0625\u064a\u0647 \u0627\u0644\u0644\u064a \u062a\u062d\u0628\u064a \u062a\u062a\u0627\u0628\u0639\u064a\u0647\u061f',
            style: TextStyle(fontSize: 13, color: secondaryText(context)),
          ),
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in periodOptionsEg)
                FilterChip(
                  label: Text(o),
                  selected: _periodOpts.contains(o),
                  onSelected: (v) async {
                    await _tick();
                    setState(() {
                      if (v) {
                        _periodOpts.add(o);
                      } else {
                        _periodOpts.remove(o);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

"""
    t = t.replace("  Widget _genderStep()", period_method + "  Widget _genderStep()")

    old_btn = (
        "            Gaps.h24,\n"
        "            ElevatedButton(\n"
        "              onPressed: _gender == null ? null : _next,\n"
        "              child: Text(l.t('next')),\n"
        "            ),\n"
        "          ],\n"
        "        ),\n"
        "      );\n\n"
        "  Widget _genderCard("
    )
    new_btn = (
        "            if (_gender == 'female') _periodSection(),\n"
        "            Gaps.h24,\n"
        "            ElevatedButton(\n"
        "              onPressed: _gender == null ? null : _next,\n"
        "              child: Text(l.t('next')),\n"
        "            ),\n"
        "          ],\n"
        "        ),\n"
        "      );\n\n"
        "  Widget _genderCard("
    )
    if old_btn in t:
        t = t.replace(old_btn, new_btn)
        print("period section injected in gender step")
    else:
        print("WARNING: gender next button block not found")

# --- Save trackPeriod in finish ---
if "p.trackPeriod" not in t:
    if "p.gender = _gender ?? '';" in t:
        t = t.replace(
            "p.gender = _gender ?? '';",
            "p.gender = _gender ?? '';\n"
            "      p.trackPeriod = _gender == 'female' && _trackPeriod;",
            1,
        )
    if "p.goals = goalsResolved;" in t:
        t = t.replace(
            "p.goals = goalsResolved;",
            "p.goals = [\n"
            "        ...goalsResolved,\n"
            "        if (_gender == 'female' && _trackPeriod) '\u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u062f\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064a\u0629',\n"
            "        ..._periodOpts,\n"
            "      ];",
            1,
        )
    if "'\u0627\u0644\u0646\u0648\u0639': _gender ?? ''," in t:
        t = t.replace(
            "'\u0627\u0644\u0646\u0648\u0639': _gender ?? '',",
            "'\u0627\u0644\u0646\u0648\u0639': _gender ?? '',\n"
            "      if (_gender == 'female')\n"
            "        '\u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u062f\u0648\u0631\u0629': _trackPeriod\n"
            "            ? ('\u0646\u0639\u0645' + (_periodOpts.isEmpty ? '' : ' \u2014 ' + _periodOpts.join('\u060c ')))\n"
            "            : '\u0644\u0627',",
            1,
        )

p.write_text(t, encoding="utf-8")
print(
    "ONB OK",
    "7DD3FC" in t,
    "F9A8D4" in t,
    "_trackPeriod" in t,
    "_periodSection" in t,
    "periodOptionsEg" in t,
    "p.trackPeriod" in t,
    "_tickAgeItem" in t,
)
