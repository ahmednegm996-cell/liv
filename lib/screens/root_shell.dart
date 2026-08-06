import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'habits_screen.dart';
import 'dreams_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
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
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.65)
              : Colors.white.withOpacity(0.75),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.12),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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
                _NavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: t.dreams,
                  selected: _index == 2,
                  accent: accent,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.smart_toy_rounded,
                  label: t.ai,
                  selected: _index == 3,
                  accent: accent,
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: t.stats,
                  selected: _index == 4,
                  accent: accent,
                  onTap: () => setState(() => _index = 4),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: t.profile,
                  selected: _index == 5,
                  accent: accent,
                  onTap: () => setState(() => _index = 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? accent : Theme.of(context).iconTheme.color?.withOpacity(0.55),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? accent : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
