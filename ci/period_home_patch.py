from pathlib import Path

# Write period screen from committed source text
src = Path("ci/period_screen.dart.txt")
p1 = Path("ci/period_screen.p1.txt")
p2 = Path("ci/period_screen.p2.txt")
text = None
if src.exists():
    text = src.read_text(encoding="utf-8")
elif p1.exists() and p2.exists():
    text = p1.read_text(encoding="utf-8") + p2.read_text(encoding="utf-8")
if text:
    out = Path("lib/screens/period_screen.dart")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")
    print("Wrote period_screen.dart", len(out.read_text().splitlines()), "lines")
else:
    print("WARNING: period screen source missing")

# trackPeriod on model
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

# Patch home
hp = Path("lib/screens/home_screen.dart")
if not hp.exists():
    print("home missing")
    raise SystemExit(0)
h = hp.read_text(encoding="utf-8")

if "period_screen.dart" not in h:
    h = h.replace(
        "import '../widgets/common.dart';\n",
        "import '../widgets/common.dart';\nimport 'period_screen.dart';\n",
        1,
    )

marker = "            // Good habits\n"
if "Period home card" not in h and marker in h:
    card = (
        "            // Period home card (feminine pink theme) — female only\n"
        "            if (state.profile.gender == 'female') ...[\n"
        "              GestureDetector(\n"
        "                onTap: () {\n"
        "                  Navigator.of(context).push(\n"
        "                    MaterialPageRoute(builder: (_) => const PeriodScreen()),\n"
        "                  );\n"
        "                },\n"
        "                child: Container(\n"
        "                  margin: const EdgeInsets.only(bottom: 16),\n"
        "                  padding: const EdgeInsets.all(16),\n"
        "                  decoration: BoxDecoration(\n"
        "                    gradient: const LinearGradient(\n"
        "                      begin: Alignment.topRight,\n"
        "                      end: Alignment.bottomLeft,\n"
        "                      colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],\n"
        "                    ),\n"
        "                    borderRadius: BorderRadius.circular(22),\n"
        "                    boxShadow: [\n"
        "                      BoxShadow(\n"
        "                        color: const Color(0xFFEC4899).withOpacity(0.28),\n"
        "                        blurRadius: 18,\n"
        "                        offset: const Offset(0, 8),\n"
        "                      ),\n"
        "                    ],\n"
        "                  ),\n"
        "                  child: Row(\n"
        "                    children: [\n"
        "                      Container(\n"
        "                        width: 48,\n"
        "                        height: 48,\n"
        "                        decoration: BoxDecoration(\n"
        "                          color: Colors.white.withOpacity(0.25),\n"
        "                          borderRadius: BorderRadius.circular(14),\n"
        "                        ),\n"
        "                        child: const Icon(\n"
        "                          Icons.water_drop_rounded,\n"
        "                          color: Colors.white,\n"
        "                          size: 26,\n"
        "                        ),\n"
        "                      ),\n"
        "                      const SizedBox(width: 12),\n"
        "                      Expanded(\n"
        "                        child: Column(\n"
        "                          crossAxisAlignment: CrossAxisAlignment.start,\n"
        "                          children: [\n"
        "                            Text(\n"
        "                              state.profile.locale == 'en'\n"
        "                                  ? 'Period Tracker'\n"
        "                                  : '\u0645\u062a\u0627\u0628\u0639\u0629 \u0627\u0644\u062f\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064a\u0629',\n"
        "                              style: const TextStyle(\n"
        "                                color: Colors.white,\n"
        "                                fontWeight: FontWeight.w900,\n"
        "                                fontSize: 16,\n"
        "                              ),\n"
        "                            ),\n"
        "                            const SizedBox(height: 4),\n"
        "                            Text(\n"
        "                              state.profile.locale == 'en'\n"
        "                                  ? 'Log flow, mood & symptoms'\n"
        "                                  : '\u0633\u062c\u0651\u0644\u064a \u0627\u0644\u062a\u062f\u0641\u0642 \u0648\u0627\u0644\u0645\u0632\u0627\u062c \u0648\u0627\u0644\u0623\u0639\u0631\u0627\u0636',\n"
        "                              style: TextStyle(\n"
        "                                color: Colors.white.withOpacity(0.88),\n"
        "                                fontSize: 12,\n"
        "                              ),\n"
        "                            ),\n"
        "                          ],\n"
        "                        ),\n"
        "                      ),\n"
        "                      const Icon(\n"
        "                        Icons.chevron_left_rounded,\n"
        "                        color: Colors.white,\n"
        "                        size: 28,\n"
        "                      ),\n"
        "                    ],\n"
        "                  ),\n"
        "                ),\n"
        "              ),\n"
        "            ],\n\n"
    )
    h = h.replace(marker, card + marker)
    print("home: period card injected")
elif "Period home card" in h:
    print("home: already present")
else:
    print("WARNING: marker not found")

hp.write_text(h, encoding="utf-8")
print("period home patch done")
