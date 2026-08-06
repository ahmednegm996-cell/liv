import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final nameCtrl = TextEditingController();
  String locale = 'en';
  final jobs = <String>{};
  final jobOptions = ['Student', 'Engineer', 'Doctor', 'Teacher', 'Freelancer', 'Other'];
  final jobOptionsAr = ['طالب', 'مهندس', 'طبيب', 'معلم', 'مستقل', 'أخرى'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('LIV', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: accent)),
              Gaps.h8,
              Text(locale == 'en' ? 'Welcome' : 'مرحبًا', style: Theme.of(context).textTheme.titleLarge),
              Gaps.h24,
              if (step == 0) ...[
                Text(locale == 'en' ? 'Choose language' : 'اختر اللغة'),
                Gaps.h12,
                Row(
                  children: [
                    Expanded(child: _chip('English', locale == 'en', () => setState(() => locale = 'en'))),
                    Gaps.w12,
                    Expanded(child: _chip('العربية', locale == 'ar', () => setState(() => locale = 'ar'))),
                  ],
                ),
              ] else if (step == 1) ...[
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: locale == 'en' ? 'Your name' : 'اسمك')),
              ] else ...[
                Text(locale == 'en' ? 'What do you do? (multi-select)' : 'ماذا تعمل؟ (اختيار متعدد)'),
                Gaps.h12,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(jobOptions.length, (i) {
                    final en = jobOptions[i];
                    final ar = jobOptionsAr[i];
                    final selected = jobs.contains(en);
                    return FilterChip(
                      label: Text(locale == 'en' ? en : ar),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) jobs.add(en); else jobs.remove(en);
                      }),
                    );
                  }),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  if (step < 2) {
                    setState(() => step++);
                  } else {
                    state.profile.name = nameCtrl.text.trim().isEmpty ? 'Friend' : nameCtrl.text.trim();
                    state.profile.locale = locale;
                    state.profile.jobs = jobs.toList();
                    await state.completeOnboarding();
                  }
                },
                child: Text(step < 2 ? t.next : t.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.purple : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
