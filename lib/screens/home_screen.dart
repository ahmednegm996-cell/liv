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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _ageController;
  Animation<double>? _ageAnimation;

  double _displayedAge = 0.0;
  int _lastAgeTick = -1;
  bool _ageAnimationStarted = false;

  @override
  void dispose() {
    _ageController?.dispose();
    super.dispose();
  }

  void _startAgeAnimation(double realAge) {
    if (_ageAnimationStarted) return;

    _ageAnimationStarted = true;

    final safeAge = realAge.clamp(0.0, 120.0);

    _ageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _ageAnimation = Tween<double>(
      begin: 0.0,
      end: safeAge,
    ).animate(
      CurvedAnimation(
        parent: _ageController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _ageAnimation!.addListener(() {
      if (!mounted) return;

      final currentAge = _ageAnimation!.value;
      final currentWholeYear = currentAge.floor();

      setState(() {
        _displayedAge = currentAge;
      });

      // Tick once for every completed year.
      if (currentWholeYear > _lastAgeTick &&
          currentWholeYear > 0 &&
          currentWholeYear <= safeAge.floor()) {
        _lastAgeTick = currentWholeYear;

        // iPhone-style light haptic + system click.
        AudioService.instance.tick();
      }
    });

    _ageController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    final realAge = state.profile.birthDate != null
        ? _calculateAge(state.profile.birthDate!)
        : 25.0;

    // Start the counter after the first frame so that the widget
    // is fully mounted before the animation begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAgeAnimation(realAge);
      }
    });

    // If the user's birth date changes while the screen is open,
    // keep the displayed value synchronized.
    final age = _ageAnimationStarted ? _displayedAge : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIV'),
      ),
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
                      Text(
                        'Lv ${state.profile.level}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      Text(
                        '${state.profile.points} XP',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Gaps.h24,

          // Body information
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.profile.locale == 'en' ? 'Body' : 'الجسم',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                Gaps.h12,

                _bar(
                  context,
                  state.profile.locale == 'en'
                      ? 'Height'
                      : 'الطول',
                  state.profile.heightCm / 220,
                  accent,
                  '${state.profile.heightCm.toStringAsFixed(0)} cm',
                ),

                Gaps.h8,

                _bar(
                  context,
                  state.profile.locale == 'en'
                      ? 'Weight'
                      : 'الوزن',
                  state.profile.weightKg / 150,
                  AppColors.teal,
                  '${state.profile.weightKg.toStringAsFixed(0)} kg',
                ),

                Gaps.h8,

                // Animated Age Counter
                _ageBar(
                  context,
                  age,
                ),
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
                    Text(
                      t.morningRoutine,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await state.addTask(
                          TaskItem(
                            title: state.profile.locale == 'en'
                                ? 'New task'
                                : 'مهمة جديدة',
                            points: 10,
                          ),
                        );

                        AudioService.instance.tick();
                      },
                    ),
                  ],
                ),

                ...state.tasks.map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: task.done,
                      onChanged: (_) {
                        state.toggleTask(task.id);

                        HapticFeedback.lightImpact();
                        AudioService.instance.tick();
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                      ),
                      onPressed: () => state.removeTask(task.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAge(DateTime birthDate) {
    final now = DateTime.now();

    final difference = now.difference(birthDate);

    return difference.inDays / 365.2425;
  }

  Widget _ageBar(
    BuildContext context,
    double age,
  ) {
    final color = AppColors.pink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'العمر',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              age.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),

        Gaps.h4,

        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: (age / 100).clamp(0.0, 1.0),
            ),
            duration: const Duration(milliseconds: 2600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: color.withOpacity(0.15),
                color: color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bar(
    BuildContext context,
    String label,
    double value,
    Color color,
    String trailing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              trailing,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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