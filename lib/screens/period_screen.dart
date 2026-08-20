import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';

class PeriodTheme {
  static const pink = Color(0xFFEC4899);
  static const pinkSoft = Color(0xFFF9A8D4);
  static const pinkDeep = Color(0xFFDB2777);
  static const blush = Color(0xFFFDF2F8);
  static const rose = Color(0xFFF472B6);
}

class PeriodDay {
  final String date;
  int flow;
  final List<String> symptoms;
  String mood;

  PeriodDay({
    required this.date,
    this.flow = 0,
    List<String>? symptoms,
    this.mood = '',
  }) : symptoms = symptoms ?? [];

  Map<String, dynamic> toJson() => {
        'date': date,
        'flow': flow,
        'symptoms': symptoms,
        'mood': mood,
      };

  factory PeriodDay.fromJson(Map<String, dynamic> j) => PeriodDay(
        date: j['date'] ?? '',
        flow: j['flow'] ?? 0,
        symptoms: List<String>.from(j['symptoms'] ?? []),
        mood: j['mood'] ?? '',
      );
}

class PeriodScreen extends StatefulWidget {
  const PeriodScreen({super.key});

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen> {
  static const _kLogs = 'liv_period_logs_v1';
  static const _kLastStart = 'liv_period_last_start_v1';
  static const _kCycleLen = 'liv_period_cycle_len_v1';

  static const symptomsAr = [
    'ألم بطن',
    'صداع',
    'تعب',
    'انتفاخ',
    'تقلبات مزاج',
    'غثيان',
  ];
  static const moods = ['😊', '😐', '😔', '😤', '🥱'];
  static const flowLabelsAr = ['بدون', 'خفيف', 'متوسط', 'كثيف'];

  final Map<String, PeriodDay> _logs = {};
  DateTime _selected = DateTime.now();
  int _cycleLen = 28;
  String? _lastStart;
  bool _loading = true;

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  PeriodDay _day(DateTime d) {
    final k = _key(d);
    return _logs.putIfAbsent(k, () => PeriodDay(date: k));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLogs);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          _logs[e.key] =
              PeriodDay.fromJson(Map<String, dynamic>.from(e.value as Map));
        }
      } catch (_) {}
    }
    _lastStart = prefs.getString(_kLastStart);
    _cycleLen = prefs.getInt(_kCycleLen) ?? 28;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final e in _logs.entries) e.key: e.value.toJson()};
    await prefs.setString(_kLogs, jsonEncode(map));
    if (_lastStart != null) await prefs.setString(_kLastStart, _lastStart!);
    await prefs.setInt(_kCycleLen, _cycleLen);
  }

  int? get _daysUntilNext {
    if (_lastStart == null) return null;
    try {
      final parts = _lastStart!.split('-');
      final start = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final next = start.add(Duration(days: _cycleLen));
      return next.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markPeriodStart() async {
    final k = _key(_selected);
    setState(() {
      _lastStart = k;
      final d = _day(_selected);
      if (d.flow == 0) d.flow = 2;
    });
    await _save();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.profile.locale == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = _day(_selected);
    final until = _daysUntilNext;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PeriodTheme.pink)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? null : PeriodTheme.blush,
      appBar: AppBar(
        title: Text(isEn ? 'Period' : 'الدورة الشهرية'),
        backgroundColor: PeriodTheme.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PeriodTheme.pinkSoft, PeriodTheme.pink],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: PeriodTheme.pink.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Cycle overview' : 'نظرة على الدورة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  until == null
                      ? (isEn
                          ? 'Tap "Period started" to begin tracking'
                          : 'اضغطي «بدأت الدورة» لبدء المتابعة')
                      : until >= 0
                          ? (isEn
                              ? 'Next period in ~$until days'
                              : 'الدورة الجاية بعد حوالي $until يوم')
                          : (isEn
                              ? 'Period may be late by ${-until} days'
                              : 'ممكن الدورة متأخرة ${-until} يوم'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: _markPeriodStart,
                        child: Text(isEn ? 'Period started' : 'بدأت الدورة'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isEn ? '$_cycleLen day cycle' : 'دورة $_cycleLen يوم',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gaps.h16,
          Text(
            isEn ? 'Selected day' : 'اليوم المحدد',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Gaps.h8,
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                    () => _selected = _selected.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _key(_selected),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                    () => _selected = _selected.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              TextButton(
                onPressed: () => setState(() => _selected = DateTime.now()),
                child: Text(isEn ? 'Today' : 'النهارده'),
              ),
            ],
          ),
          Gaps.h12,
          Text(
            isEn ? 'Flow' : 'التدفق',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < 4; i++)
                ChoiceChip(
                  label: Text(isEn
                      ? ['None', 'Light', 'Medium', 'Heavy'][i]
                      : flowLabelsAr[i]),
                  selected: d.flow == i,
                  selectedColor: PeriodTheme.pinkSoft,
                  onSelected: (_) async {
                    setState(() => d.flow = i);
                    await _save();
                    HapticFeedback.selectionClick();
                  },
                ),
            ],
          ),
          Gaps.h16,
          Text(
            isEn ? 'Mood' : 'المزاج',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Gaps.h8,
          Wrap(
            spacing: 8,
            children: [
              for (final m in moods)
                ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 20)),
                  selected: d.mood == m,
                  selectedColor: PeriodTheme.pinkSoft,
                  onSelected: (_) async {
                    setState(() => d.mood = d.mood == m ? '' : m);
                    await _save();
                    HapticFeedback.selectionClick();
                  },
                ),
            ],
          ),
          Gaps.h16,
          Text(
            isEn ? 'Symptoms' : 'الأعراض',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in symptomsAr)
                FilterChip(
                  label: Text(s),
                  selected: d.symptoms.contains(s),
                  selectedColor: PeriodTheme.pinkSoft,
                  onSelected: (v) async {
                    setState(() {
                      if (v) {
                        d.symptoms.add(s);
                      } else {
                        d.symptoms.remove(s);
                      }
                    });
                    await _save();
                    HapticFeedback.selectionClick();
                  },
                ),
            ],
          ),
          Gaps.h20,
          Text(
            isEn ? 'Average cycle length' : 'متوسط طول الدورة',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Slider(
            value: _cycleLen.toDouble(),
            min: 21,
            max: 40,
            divisions: 19,
            activeColor: PeriodTheme.pink,
            label: '$_cycleLen',
            onChanged: (v) => setState(() => _cycleLen = v.round()),
            onChangeEnd: (_) async {
              await _save();
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }
}
