import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/audio_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _otherJob = TextEditingController();
  final TextEditingController _otherHobby = TextEditingController();
  final TextEditingController _otherGoal = TextEditingController();

  int _page = 0;
  String _locale = 'ar_eg';
  bool? _isFemale;
  bool _trackPeriod = false;
  int _age = 25;
  double _height = 170;
  double _weight = 70;
  int _bedHour = 23;
  int _wakeHour = 7;
  String? _job;
  final Set<String> _hobbies = <String>{};
  final Set<String> _goals = <String>{};
  bool _analyzing = false;
  bool _finished = false;

  bool get _ar => _locale.startsWith('ar');

  String _text(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _locale = state.profile.locale;
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _otherJob.dispose();
    _otherHobby.dispose();
    _otherGoal.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 1 && _name.text.trim().isEmpty) {
      _message(_text('اكتب اسمك أولاً', 'Please enter your name first'));
      return;
    }

    if (_page < 8) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
  }

  Future<void> _back() async {
    if (_page > 0 && !_analyzing) {
      await _pages.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    if (page == 8 && !_analyzing && !_finished) {
      unawaited(_runAnalysis());
    }
  }

  Future<void> _runAnalysis() async {
    _analyzing = true;
    if (mounted) setState(() {});

    final state = context.read<AppState>();
    final profile = state.profile;

    profile.locale = _locale;
    profile.name = _name.text.trim();
    profile.gender = _isFemale == true ? 'female' : (_isFemale == false ? 'male' : '');
    profile.isFemale = _isFemale == true;
    profile.trackPeriod = _isFemale == true && _trackPeriod;
    profile.age = _age;
    profile.heightCm = _height;
    profile.weightKg = _weight;
    profile.typicalSleepHours = _sleepHours;
    profile.bedHour = _bedHour;
    profile.wakeHour = _wakeHour;
    profile.jobType = _jobValue;
    profile.hobbies = _hobbyValues;
    profile.goals = _goalValues;

    try {
      await AudioService.instance.playLoop(
        'assets/audio/meditation_ambient.mp3',
        volume: AudioService.meditationVolume,
        fadeIn: true,
      );
    } catch (_) {}

    await Future<void>.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    await state.completeOnboarding(profile.name);
    await AudioService.instance.fadeOut(
      duration: const Duration(milliseconds: 1200),
    );

    _finished = true;
    _analyzing = false;
    if (mounted) setState(() {});
  }

  double get _sleepHours {
    var hours = (_wakeHour - _bedHour) % 24;
    if (hours <= 0) hours += 24;
    return hours.toDouble();
  }

  String? get _jobValue {
    if (_job == null) return null;
    if (_job == '__other__') return _otherJob.text.trim().isEmpty ? 'Other' : _otherJob.text.trim();
    return _job;
  }

  List<String> get _hobbyValues {
    final values = _hobbies.where((x) => x != '__other__').toList();
    if (_hobbies.contains('__other__') && _otherHobby.text.trim().isNotEmpty) {
      values.add(_otherHobby.text.trim());
    }
    return values;
  }

  List<String> get _goalValues {
    final values = _goals.where((x) => x != '__other__').toList();
    if (_goals.contains('__other__') && _otherGoal.text.trim().isNotEmpty) {
      values.add(_otherGoal.text.trim());
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_page < 8) _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: _analyzing
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  _buildLanguagePage(),
                  _buildNamePage(),
                  _buildGenderPage(),
                  _buildAgePage(),
                  _buildBodyPage(),
                  _buildSleepPage(),
                  _buildJobPage(),
                  _buildInterestsPage(),
                  _buildAnalysisPage(),
                ],
              ),
            ),
            if (_page < 8) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            'LIV',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          Text(
            '${_page + 1}/8',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _page == 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Row(
        children: [
          if (_page > 0)
            TextButton(
              onPressed: _back,
              child: Text(_text('رجوع', 'Back')),
            )
          else
            const SizedBox(width: 74),
          const Spacer(),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded),
            label: Text(isLast ? _text('تحليل بياناتي', 'Analyze me') : _text('التالي', 'Next')),
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child, String? title, String? subtitle}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 28),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    return _shell(
      title: _text('أهلاً بك في LIV', 'Welcome to LIV'),
      subtitle: _text(
        'خلّي LIV يتعرّف عليك علشان يجهز تجربتك بشكل شخصي.',
        'Let LIV get to know you and personalize your experience.',
      ),
      child: Column(
        children: [
          _bigIcon(Icons.language_rounded),
          const SizedBox(height: 28),
          _choice(
            title: 'العربية',
            subtitle: 'Arabic',
            selected: _locale.startsWith('ar'),
            onTap: () => setState(() => _locale = 'ar_eg'),
          ),
          const SizedBox(height: 12),
          _choice(
            title: 'English',
            subtitle: 'English',
            selected: _locale == 'en',
            onTap: () => setState(() => _locale = 'en'),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return _shell(
      title: _text('إيه اسمك؟', 'What should we call you?'),
      subtitle: _text(
        'هنستخدم اسمك عشان نخلي LIV شخصي أكتر.',
        'Your name helps make LIV feel more personal.',
      ),
      child: Column(
        children: [
          _bigIcon(Icons.person_rounded),
          const SizedBox(height: 26),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _text('الاسم', 'Name'),
              hintText: _text('اكتب اسمك', 'Enter your name'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return _shell(
      title: _text('إيه نوعك؟', 'What is your gender?'),
      subtitle: _text(
        'المعلومة دي بتساعد LIV يخصص الاقتراحات ليك.',
        'This helps LIV personalize recommendations for you.',
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _genderCard(
                  title: _text('ذكر', 'Male'),
                  icon: Icons.male_rounded,
                  selected: _isFemale == false,
                  borderColor: const Color(0xFFFFD54F),
                  onTap: () => setState(() {
                    _isFemale = false;
                    _trackPeriod = false;
                  }),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _genderCard(
                  title: _text('أنثى', 'Female'),
                  icon: Icons.female_rounded,
                  selected: _isFemale == true,
                  borderColor: const Color(0xFFFF7DB8),
                  onTap: () => setState(() => _isFemale = true),
                ),
              ),
            ],
          ),
          if (_isFemale == true) ...[
            const SizedBox(height: 18),
            Card(
              child: SwitchListTile(
                title: Text(_text('متابعة الدورة الشهرية', 'Track period')),
                subtitle: Text(_text('اختياري ويمكن تغييره لاحقاً', 'Optional and can be changed later')),
                value: _trackPeriod,
                onChanged: (value) => setState(() => _trackPeriod = value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return _shell(
      title: _text('كام سنة عندك؟', 'How old are you?'),
      subtitle: _text('اختار سنك من العجلة.', 'Choose your age from the wheel.'),
      child: Column(
        children: [
          _bigIcon(Icons.cake_rounded),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: CupertinoPicker(
              itemExtent: 54,
              diameterRatio: 1.15,
              useMagnifier: true,
              magnification: 1.08,
              onSelectedItemChanged: (index) {
                final nextAge = 12 + index;
                if (nextAge == _age) return;
                setState(() => _age = nextAge);
                unawaited(AudioService.instance.tick());
              },
              children: List<Widget>.generate(
                89,
                (index) => Center(
                  child: Text(
                    '${12 + index}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: (12 + index) == _age ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            _text('سنة', 'years old'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPage() {
    return _shell(
      title: _text('طولك ووزنك', 'Height & weight'),
      subtitle: _text('بيانات اختيارية تساعد في تخصيص الاقتراحات.', 'Optional data that helps personalize recommendations.'),
      child: Column(
        children: [
          _sliderCard(
            icon: Icons.height_rounded,
            label: _text('الطول', 'Height'),
            valueText: '${_height.round()} cm',
            value: _height,
            min: 120,
            max: 220,
            divisions: 100,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),
          _sliderCard(
            icon: Icons.monitor_weight_rounded,
            label: _text('الوزن', 'Weight'),
            valueText: '${_weight.round()} kg',
            value: _weight,
            min: 35,
            max: 180,
            divisions: 145,
            onChanged: (v) => setState(() => _weight = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepPage() {
    return _shell(
      title: _text('نومك عامل إزاي؟', 'How do you sleep?'),
      subtitle: _text('اختار ميعاد نومك وصحيانك المعتاد.', 'Choose your usual bedtime and wake-up time.'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _timePicker(
                  icon: Icons.bedtime_rounded,
                  label: _text('النوم', 'Bedtime'),
                  value: _bedHour,
                  onChanged: (v) => setState(() => _bedHour = v),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _timePicker(
                  icon: Icons.wb_sunny_rounded,
                  label: _text('الصحيان', 'Wake up'),
                  value: _wakeHour,
                  onChanged: (v) => setState(() => _wakeHour = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(
                    _text('متوسط نومك', 'Average sleep'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_sleepHours.toStringAsFixed(1)} ${_text('ساعة', 'hours')}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobPage() {
    final jobs = <String>[
      _text('طالب', 'Student'),
      _text('موظف', 'Employee'),
      _text('عمل حر', 'Freelancer'),
      _text('صاحب عمل', 'Business owner'),
      _text('باحث عن عمل', 'Job seeker'),
      '__other__',
    ];
    return _shell(
      title: _text('بتشتغل إيه؟', 'What do you do?'),
      subtitle: _text('اختار الأقرب ليك.', 'Choose what fits you best.'),
      child: Column(
        children: [
          for (final job in jobs) ...[
            _selectTile(
              label: job == '__other__' ? _text('أخرى', 'Other') : job,
              selected: _job == job,
              onTap: () => setState(() => _job = job),
            ),
            const SizedBox(height: 10),
          ],
          if (_job == '__other__')
            TextField(
              controller: _otherJob,
              decoration: InputDecoration(
                labelText: _text('اكتب وظيفتك', 'Type your job'),
                border: const OutlineInputBorder(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    final hobbies = <String>[
      _text('رياضة', 'Sports'),
      _text('ألعاب', 'Gaming'),
      _text('قراءة', 'Reading'),
      _text('موسيقى', 'Music'),
      _text('سفر', 'Travel'),
      _text('تعلم', 'Learning'),
      _text('تصوير', 'Photography'),
      '__other__',
    ];
    final goals = <String>[
      _text('الصحة واللياقة', 'Health & fitness'),
      _text('الدراسة', 'Study'),
      _text('العمل والمال', 'Work & money'),
      _text('العلاقات', 'Relationships'),
      _text('تطوير الذات', 'Self improvement'),
      _text('الاستقرار النفسي', 'Mental wellbeing'),
      '__other__',
    ];

    return _shell(
      title: _text('إيه اللي يهمك؟', 'What matters to you?'),
      subtitle: _text('اختار أكتر من اختيار.', 'Select as many as you want.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_text('هواياتك', 'Your hobbies'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: hobbies.map((item) => _chip(item, _hobbies, _otherHobby)).toList(),
          ),
          const SizedBox(height: 22),
          Text(_text('أهدافك', 'Your goals'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: goals.map((item) => _chip(item, _goals, _otherGoal)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _finished
              ? Column(
                  key: const ValueKey('done'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bigIcon(Icons.check_circle_rounded),
                    const SizedBox(height: 26),
                    Text(
                      _text('جاهزين نبدأ 🚀', 'You are all set 🚀'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('analysis'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: CircularProgressIndicator(strokeWidth: 7),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _text('بنحلل بياناتك...', 'Analyzing your profile...'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _text('بنجهز لك تجربة LIV الشخصية.', 'We are preparing your personalized LIV experience.'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _bigIcon(IconData icon) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _choice({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        selected: selected,
        onTap: onTap,
      ),
    );
  }

  Widget _genderCard({
    required String title,
    required IconData icon,
    required bool selected,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.16) : Theme.of(context).cardColor,
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _sliderCard({
    required IconData icon,
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(valueText, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _timePicker({
    required IconData icon,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: value, minute: 0),
          );
          if (picked != null) onChanged(picked.hour);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                '${value.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectTile({required String label, required bool selected, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
        title: Text(label),
        selected: selected,
        onTap: onTap,
      ),
    );
  }

  Widget _chip(String item, Set<String> selected, TextEditingController otherController) {
    final isOther = item == '__other__';
    final label = isOther ? _text('أخرى', 'Other') : item;
    final active = selected.contains(item);
    return FilterChip(
      label: Text(label),
      selected: active,
      onSelected: (value) {
        setState(() {
          if (value) {
            selected.add(item);
          } else {
            selected.remove(item);
          }
        });
      },
    );
  }
}
