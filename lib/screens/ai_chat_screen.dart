import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart' as app_theme;

class AiChatScreen extends StatefulWidget {
  final bool active;
  const AiChatScreen({super.key, this.active = true});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;
  bool _historyLoaded = false;
  List<Map<String, String>> _pendingActions = [];

  static const _asset = 'assets/audio/meditation_ambient.mp3';

  static const _quick = [
    'حلل يومي',
    'حفزني',
    'خطة عادة',
    'نصيحة نوم',
    'رتّب أولوياتي',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      AudioService.instance.playLoop(_asset, volume: AudioService.meditationVolume);
    }
  }

  @override
  void didUpdateWidget(covariant AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      AudioService.instance.playLoop(_asset, volume: AudioService.meditationVolume);
    } else if (!widget.active && oldWidget.active) {
      AudioService.instance.fadeOut(duration: const Duration(milliseconds: 1200));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyLoaded) return;
    _historyLoaded = true;
    final saved = context.read<AppState>().profile.chatHistory;
    if (saved.isNotEmpty) {
      _messages.addAll(saved.map((e) => Map<String, String>.from(e)));
    } else {
      _messages.add({
        'role': 'assistant',
        'text':
            'أهلاً 👋 أنا Liv — مساعدك الهادئ. نرتب دماغك مع بعض بهدوء.\nتحب نبدأ بإيه؟'
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    final state = context.read<AppState>();
    final copy = _messages
        .map((m) => {'role': m['role'] ?? '', 'text': m['text'] ?? ''})
        .toList();
    final trimmed = copy.length > 40 ? copy.sublist(copy.length - 40) : copy;
    await state.updateProfile((p) {
      p.chatHistory = trimmed;
      return p;
    });
  }

  List<Map<String, String>> _parseAddTags(String reply) {
    final out = <Map<String, String>>[];
    final re = RegExp(r'\[ADD_(GOOD|BAD|TASK|DREAM):([^\]]+)\]');
    for (final m in re.allMatches(reply)) {
      final name = m.group(2)!.trim();
      if (name.isEmpty) continue;
      if (out.any((a) => a['type'] == m.group(1)! && a['name'] == name)) continue;
      out.add({'type': m.group(1)!, 'name': name});
    }
    return out;
  }

  String _stripAddTags(String reply) {
    return reply
        .replaceAll(RegExp(r'\s*\[ADD_(GOOD|BAD|TASK|DREAM):[^\]]+\]\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool _isSame(String a, String b) {
    final x = _norm(a);
    final y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    if (x.length >= 4 && y.length >= 4 && (x.contains(y) || y.contains(x))) {
      return true;
    }
    return false;
  }

  bool _alreadyExists(String type, String name) {
    final state = context.read<AppState>();
    if (type == 'TASK') {
      return state.tasks.any((t) => _isSame(t.title, name));
    }
    if (type == 'GOOD' || type == 'BAD') {
      final wantGood = type == 'GOOD';
      return state.habits.any((h) => h.isGood == wantGood && _isSame(h.name, name));
    }
    if (type == 'DREAM') {
      return state.dreams.any((d) => _isSame(d.title, name));
    }
    return false;
  }

  List<Map<String, String>> _filterNew(List<Map<String, String>> actions) {
    return actions.where((a) {
      final name = a['name'] ?? '';
      final type = a['type'] ?? '';
      if (name.isEmpty || type.isEmpty) return false;
      return !_alreadyExists(type, name);
    }).toList();
  }

  Future<void> _applyByType(String type) async {
    final batch = _pendingActions.where((a) => a['type'] == type).toList();
    if (batch.isEmpty) return;
    final state = context.read<AppState>();
    final added = <String>[];
    for (final action in batch) {
      final name = action['name'] ?? '';
      if (name.isEmpty || _alreadyExists(type, name)) continue;
      try {
        if (type == 'GOOD') {
          await state.addHabit(name, true);
          added.add(name);
        } else if (type == 'BAD') {
          await state.addHabit(name, false);
          added.add(name);
        } else if (type == 'TASK') {
          await state.addWeeklyTask(name);
          added.add(name);
        } else if (type == 'DREAM') {
          await state.addDreamWithAISteps(name, '');
          added.add(name);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _pendingActions.removeWhere((a) => a['type'] == type);
      if (added.isNotEmpty) {
        final label = type == 'TASK'
            ? 'المهام'
            : type == 'DREAM'
                ? 'الأحلام'
                : type == 'BAD'
                    ? 'العادات السيئة'
                    : 'العادات';
        _messages.add({
          'role': 'assistant',
          'text': 'تمت الإضافة إلى $label ✓\n${added.map((e) => '• $e').join('\n')}',
        });
      }
    });
    await _persist();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _sending = true;
      _pendingActions = [];
    });
    _scrollToEnd();
    await _persist();

    final state = context.read<AppState>();
    try {
      final reply = await state.ai.chat(
        userMessage: text,
        context: state.aiContext,
        history: _messages
            .map((m) => {'role': m['role']!, 'text': m['text']!})
            .toList(),
      );
      final actions = _filterNew(_parseAddTags(reply));
      final clean = _stripAddTags(reply);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': clean});
        _pendingActions = actions;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': '⚠️ $e'});
        _sending = false;
      });
    }
    await _persist();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = state.profile.hearts <= 0;
    final accent = app_theme.AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: danger
                      ? const [Color(0xFF2A0A12), Color(0xFF1A0508), Color(0xFF3B0D16)]
                      : isDark
                          ? const [Color(0xFF0B0F1A), Color(0xFF12182B), Color(0xFF0E1620), Color(0xFF1A1030)]
                          : const [Color(0xFFEEF2FF), Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withOpacity(isDark ? 0.22 : 0.18),
                      accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF6366F1) : accent)
                          .withOpacity(isDark ? 0.16 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(state, accent, danger),
                // Fixed suggestions — not inside the scrolling ListView
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                  child: _quickPrompts(accent, isDark),
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    children: [
                      ..._messages.map((m) => _bubble(m, accent)),
                      if (_sending)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _Typing(),
                          ),
                        ),
                      if (_pendingActions.isNotEmpty) _actionButtons(accent),
                    ],
                  ),
                ),
                _composer(accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppState state, Color accent, bool danger) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: danger
                      ? [app_theme.AppColors.danger, app_theme.AppColors.dangerDark]
                      : [accent, accent.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    danger ? 'Liv AI — وضع خطر' : 'Liv AI',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Text(
                    state.ai.isConfigured
                        ? 'متصل • ${state.profile.aiProvider}'
                        : 'حط API Key من البروفايل',
                    style: TextStyle(fontSize: 12, color: app_theme.secondaryText(context)),
                  ),
                ],
              ),
            ),
            if (_messages.length > 1)
              IconButton(
                tooltip: 'مسح الشات',
                onPressed: () async {
                  setState(() {
                    _pendingActions = [];
                    _messages
                      ..clear()
                      ..add({
                        'role': 'assistant',
                        'text': 'تم مسح المحادثة. نبدأ من جديد؟'
                      });
                  });
                  await _persist();
                },
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      );

  /// Compact suggestion chips — same visual language as onboarding choices.
  Widget _quickPrompts(Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in _quick)
            ActionChip(
              label: Text(t, style: const TextStyle(fontSize: 13)),
              onPressed: _sending ? null : () => _send(t),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons(Color accent) {
    final types = <String>[];
    for (final a in _pendingActions) {
      final t = a['type'];
      if (t != null && !types.contains(t)) types.add(t);
    }
    String labelFor(String type) {
      switch (type) {
        case 'TASK':
          return 'إضافة للمهمات';
        case 'GOOD':
          return 'إضافة للعادات';
        case 'BAD':
          return 'إضافة للعادات السيئة';
        case 'DREAM':
          return 'إضافة للأحلام';
        default:
          return 'إضافة';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: () => _applyByType(type),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
                label: Text(labelFor(type)),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, String> m, Color accent) {
    final isUser = m['role'] == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? accent
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 6 : 20),
            bottomRight: Radius.circular(isUser ? 20 : 6),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? accent : Colors.black).withOpacity(isUser ? 0.22 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          m['text'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : null,
            height: 1.5,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _composer(Color accent) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'اكتب لـ Liv...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _send(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      );
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text('Liv بيفكر...', style: TextStyle(color: app_theme.secondaryText(context), fontSize: 13)),
        ],
      ),
    );
  }
}
