from pathlib import Path

# 1) Write period screen
src = Path("ci/period_screen.dart.txt")
if src.exists():
    Path("lib/screens/period_screen.dart").write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    print("Wrote period_screen.dart from ci/period_screen.dart.txt")
else:
    print("WARNING: ci/period_screen.dart.txt missing")

# 2) Patch root_shell.dart — add Period tab for female users
rp = Path("lib/screens/root_shell.dart")
if not rp.exists():
    print("WARNING: root_shell.dart missing")
    raise SystemExit(0)

t = rp.read_text(encoding="utf-8")
if "PeriodScreen" in t and "_showPeriod" in t:
    print("root_shell: period tab already present")
    raise SystemExit(0)

if "import 'period_screen.dart';" not in t:
    t = t.replace(
        "import 'stats_screen.dart';\n",
        "import 'stats_screen.dart';\nimport 'period_screen.dart';\n",
        1,
    )

old_state = """class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    HabitsScreen(),
    DreamsScreen(),
    AiChatScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
"""

new_state = """class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);
    final showPeriod = state.profile.gender == 'female';

    final pages = <Widget>[
      const HomeScreen(),
      const HabitsScreen(),
      if (showPeriod) const PeriodScreen(),
      const DreamsScreen(),
      const AiChatScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];

    if (_index >= pages.length) {
      _index = pages.length - 1;
    }

    final navItems = <Widget>[
      _NavItem(
        icon: Icons.home_rounded,
        label: t.home,
        selected: _index == 0,
        accent: accent,
        onTap: () => setState(() => _index = 0),
      ),
      _NavItem(
        icon: Icons.check_circle_outline_rounded,
        label: t.habits,
        selected: _index == 1,
        accent: accent,
        onTap: () => setState(() => _index = 1),
      ),
    ];

    int next = 2;
    if (showPeriod) {
      final periodIndex = next;
      navItems.add(
        _NavItem(
          icon: Icons.water_drop_rounded,
          label: state.profile.locale == 'en' ? 'Period' : 'الدورة',
          selected: _index == periodIndex,
          accent: const Color(0xFFEC4899),
          onTap: () => setState(() => _index = periodIndex),
        ),
      );
      next++;
    }

    final dreamsIndex = next;
    navItems.add(
      _NavItem(
        icon: Icons.auto_awesome_rounded,
        label: t.dreams,
        selected: _index == dreamsIndex,
        accent: accent,
        onTap: () => setState(() => _index = dreamsIndex),
      ),
    );
    next++;

    final aiIndex = next;
    navItems.add(
      _NavItem(
        icon: Icons.smart_toy_rounded,
        label: t.ai,
        selected: _index == aiIndex,
        accent: accent,
        onTap: () => setState(() => _index = aiIndex),
      ),
    );
    next++;

    final statsIndex = next;
    navItems.add(
      _NavItem(
        icon: Icons.bar_chart_rounded,
        label: t.stats,
        selected: _index == statsIndex,
        accent: accent,
        onTap: () => setState(() => _index = statsIndex),
      ),
    );
    next++;

    final profileIndex = next;
    navItems.add(
      _NavItem(
        icon: Icons.person_rounded,
        label: t.profile,
        selected: _index == profileIndex,
        accent: accent,
        onTap: () => setState(() => _index = profileIndex),
      ),
    );

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
"""

if old_state in t:
    t = t.replace(old_state, new_state)
    print("root_shell: state/build replaced")
else:
    print("WARNING: root_shell state block not exact match")

import re
pattern = r'(child: Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceAround,\s*children: \[)([\s\S]*?)(\],\s*\),\s*\),\s*\),\s*\),\s*\);\s*\}\s*\})'
m = re.search(pattern, t)
if m and "navItems" in t and "...navItems" not in t:
    t = t[:m.start(1)] + m.group(1) + "\n                ...navItems,\n              " + m.group(3) + t[m.end():]
    print("root_shell: nav children swapped to navItems")
elif "...navItems" in t:
    print("root_shell: navItems already spread")
else:
    print("WARNING: could not swap nav children", bool(m))

rp.write_text(t, encoding="utf-8")
print("root_shell done", "PeriodScreen" in t, "showPeriod" in t, "...navItems" in t)
