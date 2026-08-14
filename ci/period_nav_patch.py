from pathlib import Path

# 1) Write PeriodScreen
src = Path("ci/period_screen.dart.txt")
out = Path("lib/screens/period_screen.dart")
out.parent.mkdir(parents=True, exist_ok=True)
if src.exists():
    out.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    print("Wrote period_screen.dart", len(out.read_text().splitlines()), "lines")
else:
    print("WARNING: ci/period_screen.dart.txt missing")

# 2) Rewrite root_shell with Period tab (female only), matching ZIP structure
rp = Path("lib/screens/root_shell.dart")
if not rp.exists():
    print("WARNING: root_shell.dart missing")
    raise SystemExit(0)

new_root = r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/l10n.dart';
import 'home_screen.dart';
import 'habits_screen.dart';
import 'dreams_screen.dart';
import 'stats_screen.dart';
import 'period_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = L10n(state.profile.locale);
    final showPeriod = state.profile.gender == 'female';

    // Order: Home, Habits, [Period if female], AI, Stats, Dreams, Profile
    final screens = <Widget>[
      const HomeScreen(),
      const HabitsScreen(),
      if (showPeriod) const PeriodScreen(),
      AIChatScreen(active: _index == (showPeriod ? 3 : 2)),
      const StatsScreen(),
      const DreamsScreen(),
      const ProfileScreen(),
    ];

    if (_index >= screens.length) {
      _index = screens.length - 1;
    }

    final aiIndex = showPeriod ? 3 : 2;

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: l.t('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.checklist_outlined),
        selectedIcon: const Icon(Icons.checklist_rounded),
        label: l.t('habits'),
      ),
      if (showPeriod)
        NavigationDestination(
          icon: const Icon(Icons.water_drop_outlined),
          selectedIcon: const Icon(Icons.water_drop_rounded),
          label: state.profile.locale == 'en' ? 'Period' : 'الدورة',
        ),
      NavigationDestination(
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome_rounded),
        label: l.t('ai'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart_rounded),
        label: l.t('stats'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.star_outline_rounded),
        selectedIcon: const Icon(Icons.star_rounded),
        label: l.t('dreams'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: l.t('profile'),
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          return FadeTransition(opacity: anim, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: screens[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (_index == aiIndex && i != aiIndex) {
            AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200));
          }
          setState(() => _index = i);
        },
        destinations: destinations,
      ),
    );
  }
}
"""

rp.write_text(new_root, encoding="utf-8")
print("root_shell rewritten with Period tab")
print("markers", "PeriodScreen" in new_root, "showPeriod" in new_root, "water_drop" in new_root)
