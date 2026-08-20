import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool? _isFemale;
  bool _trackPeriod = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(AppState state) {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      state.profile.name = name;
    }

    state.profile.isFemale = _isFemale ?? false;
    state.profile.trackPeriod = (_isFemale == true) && _trackPeriod;

    state.completeOnboarding();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final t = L10n.of(state.profile.locale);

    final isArabic = state.profile.locale == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildGoalsPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(
                        isArabic ? 'رجوع' : 'Back',
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _nextPage(state),
                    child: Text(
                      _currentPage < 2
                          ? t.next
                          : (isArabic ? 'ابدأ' : 'Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to LIV',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'A simple space to organize your life, build better habits, and work toward your dreams.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 28),
            Text(
              'What should we call you?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tell LIV your name so your experience feels more personal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsPage() {
    final isArabic = context.read<AppState>().profile.locale.startsWith('ar');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 28),
            Text(
              'Build the life you want',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Track your habits, dreams, progress, and daily activities in one place.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _goalItem(
                      Icons.check_circle_outline,
                      'Build better habits',
                    ),
                    const SizedBox(height: 16),
                    _goalItem(
                      Icons.auto_awesome_outlined,
                      'Work toward your dreams',
                    ),
                    const SizedBox(height: 16),
                    _goalItem(
                      Icons.insights_outlined,
                      'Understand your progress',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isArabic ? 'الجنس' : 'Gender',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _genderChoice(
                    label: isArabic ? 'ذكر' : 'Male',
                    selected: _isFemale == false,
                    onTap: () => setState(() {
                      _isFemale = false;
                      _trackPeriod = false;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _genderChoice(
                    label: isArabic ? 'أنثى' : 'Female',
                    selected: _isFemale == true,
                    onTap: () => setState(() => _isFemale = true),
                  ),
                ),
              ],
            ),
            if (_isFemale == true) ...[
              const SizedBox(height: 20),
              Card(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    isArabic ? 'متابعة الدورة الشهرية' : 'Track period',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isArabic
                        ? 'اختياري — يمكنك تفعيلها لاحقاً'
                        : 'Optional — you can enable later',
                  ),
                  value: _trackPeriod,
                  activeColor: const Color(0xFFF9A8D4),
                  onChanged: (v) => setState(() => _trackPeriod = v),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _genderChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withOpacity(0.18) : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
