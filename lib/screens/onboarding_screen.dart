import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _page = PageController();
  int _step = 0;
  bool _loading = false;
  bool _analyzing = false;

  final _name = TextEditingController();
  final _api = TextEditingController();
  final _otherJob = TextEditingController();
  final _otherGoal = TextEditingController();
  final _otherHabit = TextEditingController();

  String _locale = 'ar_eg';
  String? _gender;
  final Set<String> _jobs = {};
  final Set<String> _goals = {};
  final Set<String> _habitWant = {};
  int _age = 22;

  int _bedHour12 = 11;
  int _bedMinute = 0;
  bool _bedIsPm = true;
  int _wakeHour12 = 7;
  int _wakeMinute = 0;
  bool _wakeIsPm = false;

  late AnimationController _analyzeCtrl;
  late Animation<double> _analyzePulse;

  static const jobsEg = [
    'طالب',
    'موظف',
    'فريلانسر',
    'رائد أعمال',
    'سائق / توصيل',
    'ربة منزل',
    'بدون عمل حالياً',
    'أخرى'
  ];
  static const goalsEg = [
    'تحسين الصحة',
    'زيادة الدخل',
    'تعلم مهارة',
    'تنظيم الوقت',
    'خسارة/زيادة وزن',
    'بناء عادة يومية',
    'تحسين النوم',
    'تقليل التوتر',
    'أخرى'
  ];
  static const goodHabitsEg = [
    'رياضة يومية',
    'قراءة',
    'شرب مياه كفاية',
    'نوم منتظم',
    'مذاكرة / شغل بتركيز',
    'مشي',
    'تأمل',
    'كتابة يوميات',
    'أخرى'
  ];

  static const _maleColor = Color(0xFFB8956A);
  static const _femaleColor = Color(0xFFEC4899);

  int get total => 10;

  L10n get l => L10n(_locale);

  @override
  void initState() {
    super.initState();
    _analyzeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _analyzePulse = Tween<double>(begin: 0.85, end: 1.12).animate(
      CurvedAnimation(parent: _analyzeCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _api.dispose();
    _otherJob.dispose();
    _otherGoal.dispose();
    _otherHabit.dispose();
    _analyzeCtrl.dispose();
    super.dispose();
  }

  int _to24(int h12, bool isPm) {
    if (h12 == 12) return isPm ? 12 : 0;
    return isPm ? h12 + 12 : h12;
  }

  Future<void> _tick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    } catch (_) {}
    try {
      await AudioService.instance.tick();
    } catch (_) {}
  }

  Future<void> _next() async {
    await _tick();
    if (_step >= total - 1) return;
    setState(() => _step++);
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    await _tick();
    if (_step <= 0) return;
    setState(() => _step--);
    _page.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  String get _localeLabel {
    switch (_locale) {
      case 'en':
        return 'English';
      case 'ar':
        return 'عربي فصحى';
      default:
        return 'عربي مصري';
    }
  }

  Future<void> _pickLanguage() async {
    await _tick();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Gaps.h16,
                Text(
                  l.t('language'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Gaps.h16,
                for (final e in [
                  ('ar_eg', 'عربي مصري'),
                  ('ar', 'عربي فصحى'),
                  ('en', 'English'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: _locale == e.$1
                          ? AppColors.primary.withOpacity(0.18)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(ctx, e.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _locale == e.$1
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.$2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _locale == e.$1
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                              ),
                              if (_locale == e.$1)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null) {
      setState(() => _locale = chosen);
      await _tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_analyzing) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _analyzePulse,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Gaps.h32,
                  Text(
                    _locale.startsWith('ar')
                        ? 'جارٍ تحليل شخصيتك...'
                        : 'Analyzing your personality...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Gaps.h12,
                  Text(
                    _locale.startsWith('ar')
                        ? 'بنحط خطة مناسبة ليك بناءً على اختياراتك'
                        : 'Creating a plan tailored to your answers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  Gaps.h32,
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / total,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcome(),
                  _langStep(),
                  _genderStep(),
                  _nameStep(),
                  _ageStep(),
                  _jobStep(),
                  _sleepStep(),
                  _goalsStep(),
                  _habitStep(),
                  _apiStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shell({required Widget child}) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: child),
      );

  Widget _welcome() => _shell(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            Gaps.h20,
            const Text(
              'Liv',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Gaps.h12,
            Text(
              'هنفهم يومك الأول، وبعدين نبني بداية بسيطة تقدر تلتزم بيها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText(context),
                height: 1.55,
                fontSize: 15,
              ),
            ),
            Gaps.h24,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(l.t('lets_start')),
              ),
            ),
          ],
        ),
      );

  Widget _langStep() => _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('language'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Gaps.h8,
            Text(
              _locale.startsWith('ar')
                  ? 'اضغط على الصندوق لاختيار اللغة'
                  : 'Tap the box to choose language',
              style: TextStyle(color: secondaryText(context), fontSize: 13),
            ),
            Gaps.h16,
            Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primary),
                      Gaps.w12,
                      Expanded(
                        child: Text(
                          _localeLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: secondaryText(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gaps.h24,
            ElevatedButton(
              onPressed: _next,
              child: Text(l.t('next')),
            ),
          ],
        ),
      );

  Widget _genderStep() => _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('gender'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Gaps.h16,
            Row(
              children: [
                Expanded(
                  child: _genderCard(
                    Icons.male_rounded,
                    l.t('male'),
                    'male',
                    _maleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _genderCard(
                    Icons.female_rounded,
                    l.t('female'),
                    'female',
                    _femaleColor,
                  ),
                ),
              ],
            ),
            Gaps.h24,
            ElevatedButton(
              onPressed: _gender == null ? null : _next,
              child: Text(l.t('next')),
            ),
          ],
        ),
      );

  Widget _genderCard(
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () async {
        await _tick();
        setState(() => _gender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.22) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color: selected ? accent : secondaryText(context),
            ),
            Gaps.h8,
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: selected ? accent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameStep() => _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('your_name'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Gaps.h16,
            SectionCard(
              child: TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'أحمد / Sara'),
              ),
            ),
            Gaps.h24,
            ElevatedButton(
              onPressed: _next,
              child: Text(l.t('next')),
            ),
          ],
        ),
      );

  Widget _ageStep() => _shell(
        child: Column(
          children: [
            Text(
              l.t('your_age'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Gaps.h16,
            SizedBox(
              height: 180,
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController:
                    FixedExtentScrollController(initialItem: _age - 12),
                onSelectedItemChanged: (i) async {
                  await _tick();
                  setState(() => _age = i + 12);
                },
                children: [
                  for (int a = 12; a <= 80; a++)
                    Center(
                      child: Text(
                        '$a ${l.t('years')}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                ],
              ),
            ),
            Gaps.h16,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(l.t('next')),
              ),
            ),
          ],
        ),
      );

  Widget _jobStep() {
    final hasOther = _jobs.contains('أخرى');
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.t('job'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Gaps.h8,
          Text(
            l.t('select_multi'),
            style: TextStyle(color: secondaryText(context), fontSize: 13),
          ),
          Gaps.h16,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in jobsEg)
                FilterChip(
                  label: Text(o),
                  selected: _jobs.contains(o),
                  onSelected: (v) async {
                    await _tick();
                    setState(() {
                      if (v) {
                        _jobs.add(o);
                      } else {
                        _jobs.remove(o);
                        if (o == 'أخرى') _otherJob.clear();
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.25),
                ),
            ],
          ),
          if (hasOther) ...[
            Gaps.h16,
            SectionCard(
              child: TextField(
                controller: _otherJob,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: _locale.startsWith('ar')
                      ? 'اكتب وظيفتك هنا...'
                      : 'Type your job here...',
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                ),
              ),
            ),
          ],
          Gaps.h24,
          ElevatedButton(
            onPressed: _jobs.isEmpty
                ? null
                : () {
                    if (hasOther && _otherJob.text.trim().isEmpty) return;
                    _next();
                  },
            child: Text(l.t('next')),
          ),
        ],
      ),
    );
  }

  Widget _sleepStep() => _shell(
        child: Column(
          children: [
            Text(
              l.t('sleep_wake'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Gaps.h8,
            Text(
              '12-hour • AM / PM',
              style: TextStyle(color: secondaryText(context)),
            ),
            Gaps.h16,
            Text(
              l.t('bed_at'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            _timePicker12(
              hour: _bedHour12,
              minute: _bedMinute,
              isPm: _bedIsPm,
              onHour: (v) async {
                await _tick();
                setState(() => _bedHour12 = v);
              },
              onMinute: (v) async {
                await _tick();
                setState(() => _bedMinute = v);
              },
              onPm: (v) async {
                await _tick();
                setState(() => _bedIsPm = v);
              },
            ),
            Gaps.h12,
            Text(
              l.t('wake_at'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            _timePicker12(
              hour: _wakeHour12,
              minute: _wakeMinute,
              isPm: _wakeIsPm,
              onHour: (v) async {
                await _tick();
                setState(() => _wakeHour12 = v);
              },
              onMinute: (v) async {
                await _tick();
                setState(() => _wakeMinute = v);
              },
              onPm: (v) async {
                await _tick();
                setState(() => _wakeIsPm = v);
              },
            ),
            Gaps.h16,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(l.t('next')),
              ),
            ),
          ],
        ),
      );

  Widget _timePicker12({
    required int hour,
    required int minute,
    required bool isPm,
    required ValueChanged<int> onHour,
    required ValueChanged<int> onMinute,
    required ValueChanged<bool> onPm,
  }) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController:
                  FixedExtentScrollController(initialItem: hour - 1),
              onSelectedItemChanged: (i) => onHour(i + 1),
              children: [
                for (int h = 1; h <= 12; h++) Center(child: Text('$h')),
              ],
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 22)),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController:
                  FixedExtentScrollController(initialItem: minute),
              onSelectedItemChanged: onMinute,
              children: [
                for (int m = 0; m < 60; m++)
                  Center(child: Text(m.toString().padLeft(2, '0'))),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController:
                  FixedExtentScrollController(initialItem: isPm ? 1 : 0),
              onSelectedItemChanged: (i) => onPm(i == 1),
              children: [
                Center(child: Text(l.t('am'))),
                Center(child: Text(l.t('pm'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalsStep() {
    final hasOther = _goals.contains('أخرى');
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.t('goals'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Gaps.h8,
          Text(
            l.t('select_multi'),
            style: TextStyle(color: secondaryText(context), fontSize: 13),
          ),
          Gaps.h16,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in goalsEg)
                FilterChip(
                  label: Text(o),
                  selected: _goals.contains(o),
                  onSelected: (v) async {
                    await _tick();
                    setState(() {
                      if (v) {
                        _goals.add(o);
                      } else {
                        _goals.remove(o);
                        if (o == 'أخرى') _otherGoal.clear();
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.25),
                ),
            ],
          ),
          if (hasOther) ...[
            Gaps.h16,
            SectionCard(
              child: TextField(
                controller: _otherGoal,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: _locale.startsWith('ar')
                      ? 'اكتب هدفك هنا...'
                      : 'Type your goal here...',
                  prefixIcon: const Icon(Icons.flag_outlined),
                ),
              ),
            ),
          ],
          Gaps.h24,
          ElevatedButton(
            onPressed: _goals.isEmpty
                ? null
                : () {
                    if (hasOther && _otherGoal.text.trim().isEmpty) return;
                    _next();
                  },
            child: Text(l.t('next')),
          ),
        ],
      ),
    );
  }

  Widget _habitStep() {
    final hasOther = _habitWant.contains('أخرى');
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.t('habit_want'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Gaps.h8,
          Text(
            l.t('select_multi'),
            style: TextStyle(color: secondaryText(context), fontSize: 13),
          ),
          Gaps.h16,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in goodHabitsEg)
                FilterChip(
                  label: Text(o),
                  selected: _habitWant.contains(o),
                  onSelected: (v) async {
                    await _tick();
                    setState(() {
                      if (v) {
                        _habitWant.add(o);
                      } else {
                        _habitWant.remove(o);
                        if (o == 'أخرى') _otherHabit.clear();
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.25),
                ),
            ],
          ),
          if (hasOther) ...[
            Gaps.h16,
            SectionCard(
              child: TextField(
                controller: _otherHabit,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: _locale.startsWith('ar')
                      ? 'اكتب العادة هنا...'
                      : 'Type the habit here...',
                  prefixIcon: const Icon(Icons.auto_graph_rounded),
                ),
              ),
            ),
          ],
          Gaps.h24,
          ElevatedButton(
            onPressed: _habitWant.isEmpty
                ? null
                : () {
                    if (hasOther && _otherHabit.text.trim().isEmpty) return;
                    _next();
                  },
            child: Text(l.t('next')),
          ),
        ],
      ),
    );
  }

  Widget _apiStep() => _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.key_rounded, size: 48, color: AppColors.primary),
            Gaps.h12,
            Text(
              l.t('api_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Gaps.h8,
            Text(
              '1) aistudio.google.com/apikey\n2) Create API key\n3) Paste here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText(context),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            Gaps.h16,
            TextField(
              controller: _api,
              obscureText: true,
              decoration: InputDecoration(
                hintText: l.t('api_hint'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            Gaps.h24,
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _startAnalyzeThenFinish,
                child: Text(l.t('build_start')),
              ),
              TextButton(
                onPressed: _startAnalyzeThenFinish,
                child: Text(l.t('skip_api')),
              ),
            ],
          ],
        ),
      );

  double _sleepHours() {
    final bed = _to24(_bedHour12, _bedIsPm) * 60 + _bedMinute;
    final wake = _to24(_wakeHour12, _wakeIsPm) * 60 + _wakeMinute;
    int diff = wake - bed;
    if (diff <= 0) diff += 24 * 60;
    return diff / 60.0;
  }

  Future<void> _startAnalyzeThenFinish() async {
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final name =
        _name.text.trim().isEmpty ? 'Friend' : _name.text.trim();
    final hours = _sleepHours();
    final bed24 = _to24(_bedHour12, _bedIsPm);
    final wake24 = _to24(_wakeHour12, _wakeIsPm);

    final jobsResolved = _jobs.map((j) {
      if (j == 'أخرى' && _otherJob.text.trim().isNotEmpty) {
        return _otherJob.text.trim();
      }
      return j;
    }).where((j) => j != 'أخرى').toList();

    final goalsResolved = _goals.map((g) {
      if (g == 'أخرى' && _otherGoal.text.trim().isNotEmpty) {
        return _otherGoal.text.trim();
      }
      return g;
    }).where((g) => g != 'أخرى').toList();

    final habitsResolved = _habitWant.map((h) {
      if (h == 'أخرى' && _otherHabit.text.trim().isNotEmpty) {
        return _otherHabit.text.trim();
      }
      return h;
    }).where((h) => h != 'أخرى').toList();

    final primaryJob =
        jobsResolved.isNotEmpty ? jobsResolved.first : null;

    await state.updateProfile((p) {
      p.name = name;
      p.age = _age;
      p.gender = _gender ?? '';
      p.locale = _locale;
      p.jobType = primaryJob;
      p.bedHour = bed24;
      p.wakeHour = wake24;
      p.typicalSleepHours = hours;
      p.geminiApiKey = _api.text.trim();
      p.geminiModel = 'gemini-flash-lite-latest';
      p.aiProvider = 'gemini';
      p.goals = goalsResolved;
      return p;
    });

    await state.logSleep(hours);

    for (final h in habitsResolved) {
      await state.addHabit(h, true);
    }

    final answers = <String, String>{
      'اسمك': name,
      'النوع': _gender ?? '',
      'العمر': '$_age',
      'الشغل': jobsResolved.join('، '),
      'الأهداف': goalsResolved.join('، '),
      'عادات كويسة': habitsResolved.join('، '),
    };

    if (_api.text.trim().isNotEmpty) {
      try {
        await state.buildStarterPlan(answers);
      } catch (_) {}
    }

    await state.completeOnboarding(name);
    if (mounted) {
      setState(() {
        _loading = false;
        _analyzing = false;
      });
    }
  }
}
