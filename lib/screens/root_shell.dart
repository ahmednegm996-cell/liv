import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import 'home_screen.dart';
import 'habits_screen.dart';
import 'dreams_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'period_screen.dart';

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
    final t = L10n.of(state.profile.locale);
    final showPeriod =
        state.profile.isFemale && state.profile.trackPeriod;

    // Order: Home → Habits → [Period] → AI → Stats → Dreams → Profile
    final aiIndex = showPeriod ? 3 : 2;
    final pages = <Widget>[
      const HomeScreen(),
      const HabitsScreen(),
      if (showPeriod) const PeriodScreen(),
      AIChatScreen(active: _index == aiIndex),
      const StatsScreen(),
      const DreamsScreen(),
      const ProfileScreen(),
    ];

    // Clamp safely without side-effects during build when possible
    final safeIndex = _index.clamp(0, pages.length - 1);
    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = safeIndex);
      });
    }

    final isAr = state.profile.locale.startsWith('ar');
    final periodLabel = isAr ? 'الدورة' : 'Period';

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: t.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.checklist_outlined),
        selectedIcon: const Icon(Icons.checklist_rounded),
        label: t.habits,
      ),
      if (showPeriod)
        NavigationDestination(
          icon: const Icon(Icons.water_drop_outlined),
          selectedIcon: const Icon(Icons.water_drop_rounded),
          label: periodLabel,
        ),
      NavigationDestination(
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome_rounded),
        label: t.ai,
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart_rounded),
        label: t.stats,
      ),
      NavigationDestination(
        icon: const Icon(Icons.star_outline_rounded),
        selectedIcon: const Icon(Icons.star_rounded),
        label: t.dreams,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: t.profile,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: destinations,
      ),
    );
  }
}
