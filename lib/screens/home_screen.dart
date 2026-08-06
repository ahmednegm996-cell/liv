import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);
    final age = state.profile.birthDate != null
        ? DateTime.now().difference(state.profile.birthDate!).inDays / 365.25
        : 25.0;

    return Scaffold(
      appBar: AppBar(title: const Text('LIV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Large progress circle
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: (state.profile.points % 100) / 100,
                      strokeWidth: 14,
                      backgroundColor: accent.withOpacity(0.15),
                      color: accent,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lv ${state.profile.level}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accent)),
                      Text('${state.profile.points} XP', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Gaps.h24,
          // Horizontal bars
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.profile.locale == 'en' ? 'Body' : 'الجسم', style: Theme.of(context).textTheme.titleMedium),
                Gaps.h12,
                _bar(context, state.profile.locale == 'en' ? 'Height' : 'الطول', state.profile.heightCm / 220, accent, '${state.profile.heightCm.toStringAsFixed(0)} cm'),
                Gaps.h8,
                _bar(context, state.profile.locale == 'en' ? 'Weight' : 'الوزن', state.profile.weightKg / 150, AppColors.teal, '${state.profile.weightKg.toStringAsFixed(0)} kg'),
                Gaps.h8,
                _bar(context, state.profile.locale == 'en' ? 'Age' : 'العمر', age / 100, AppColors.pink, age.toStringAsFixed(1)),
              ],
            ),
          ),
          Gaps.h16,
          // Daily tasks
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.morningRoutine, style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await state.addTask(TaskItem(title: state.profile.locale == 'en' ? 'New task' : 'مهمة جديدة', points: 10));
                        AudioService.instance.tick();
                      },
                    ),
                  ],
                ),
                ...state.tasks.map((task) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: task.done,
                        onChanged: (_) {
                          state.toggleTask(task.id);
                          HapticFeedback.lightImpact();
                          AudioService.instance.tick();
                        },
                      ),
                      title: Text(task.title, style: TextStyle(decoration: task.done ? TextDecoration.lineThrough : null)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => state.removeTask(task.id),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double value, Color color, String trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(trailing, style: Theme.of(context).textTheme.bodySmall)],
        ),
        Gaps.h4,
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withOpacity(0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}
