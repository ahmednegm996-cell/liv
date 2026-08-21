import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.habits),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Simple add using Phase-4 compatible API (Habit instance or name/isGood)
              final title = t.add_habit;
              await state.addHabit(Habit(title: title, isGood: true));
            },
          ),
        ],
      ),
      body: state.habits.isEmpty
          ? Center(child: Text(t.no_habits))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.habits.length,
              itemBuilder: (context, i) {
                final h = state.habits[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        h.isGood ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: h.isGood ? accent : Colors.orange,
                      ),
                      title: Text(h.titleAr ?? h.title),
                      subtitle: Text('Streak: ${h.currentStreak} · ${h.totalCompletions}x'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.removeHabit(h.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
