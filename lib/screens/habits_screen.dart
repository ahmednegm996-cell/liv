import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../widgets/common.dart';
import '../models.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.habits),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await state.addHabit(Habit(title: state.profile.locale == 'en' ? 'New habit' : 'عادة جديدة'));
            },
          ),
        ],
      ),
      body: state.habits.isEmpty
          ? Center(child: Text(state.profile.locale == 'en' ? 'No habits yet. Add one!' : 'لا عادات بعد. أضف واحدةً!'))
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
                      title: Text(h.title),
                      subtitle: Text('Streak: ${h.currentStreak}'),
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
