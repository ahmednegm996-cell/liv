import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: accent.withOpacity(0.2), child: Text(state.profile.name.isNotEmpty ? state.profile.name[0].toUpperCase() : 'L', style: TextStyle(fontSize: 32, color: accent))),
                Gaps.h12,
                Text(state.profile.name, style: Theme.of(context).textTheme.titleLarge),
                Text('Lv ${state.profile.level} · ${state.profile.points} XP'),
              ],
            ),
          ),
          Gaps.h16,
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.profile.locale == 'en' ? 'Language' : 'اللغة'),
                Gaps.h8,
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {state.profile.locale},
                  onSelectionChanged: (s) {
                    state.profile.locale = s.first;
                    state.saveProfile();
                  },
                ),
                Gaps.h16,
                Text(state.profile.locale == 'en' ? 'Theme color' : 'لون السمة'),
                Gaps.h8,
                Wrap(
                  spacing: 8,
                  children: ['purple', 'teal', 'blue', 'pink', 'orange', 'green', 'indigo'].map((c) {
                    final col = AppColors.accentFrom(c);
                    final selected = state.profile.accentColor == c;
                    return GestureDetector(
                      onTap: () {
                        state.profile.accentColor = c;
                        state.saveProfile();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: selected ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (state.profile.isFemale) ...[
                  Gaps.h16,
                  Text(t.periodTracking),
                  Text(state.profile.locale == 'en' ? 'Cycle length: ${state.profile.cycleLengthDays} days' : 'طول الدورة: ${state.profile.cycleLengthDays} يوم'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
