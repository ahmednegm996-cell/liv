import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AIChatScreen extends StatefulWidget {
  final bool active;
  const AIChatScreen({super.key, this.active = true});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
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
    'خطة لع عادة',
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
  void didUpdateWidget(covariant AIChatScreen oldWidget) {
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
    final re = RegExp(r'\[ADD_(GOOD|BAD|TASK):([^\]]+)\]');
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
        .replaceAll(RegExp(r'\s*\[ADD_(GOOD|BAD|TASK):[^\]]+\]\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _applyAllActions() async {
    if (_pendingActions.isEmpty) return;
    final state = context.read<AppState>();
    final actions = List<Map<String, String>>.from(_pendingActions);
    final added = <String>[];
    for (final action in actions) {
      final name = action['name'] ?? '';
      if (name.isEmpty) continue;
      try {
        final type = action['type'];
        if (type == 'GOOD') {
          await state.addHabit(name, true);
          added.add('عادة جيدة: $name');
        } else if (type == 'BAD') {
          await state.addHabit(name, false);
          added.add('عادة سيئة: $name');
        } else if (type == 'TASK') {
          await state.addWeeklyTask(name);
          added.add('مهمة: $name');
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _pendingActions = [];
      if (added.isNotEmpty) {
        _messages.add({
          'role': 'assistant',
          'text': 'تمت الإضافة ✓\n${added.map((e) => '• $e').join('\n')}',
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
      final actions = _parseAddTags(reply);
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
    final accent = AppColors.accentFrom(state.profile.accentColor);

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
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    children: [
                      if (_messages.length <= 1) _quickPrompts(accent, isDark),
                      ..._messages.map((m) => _bubble(m, accent)),
                      if (_sending)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _Typing(),
                          ),
                        ),
                      if (_pendingActions.isNotEmpty) _addAllButton(accent),
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
                      ? [AppColors.danger, AppColors.dangerDark]
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
                    style: TextStyle(fontSize: 12, color: secondaryText(context)),
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

  /// Vertical full-width suggestion boxes (not horizontal chips).
  Widget _quickPrompts(Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in _quick)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _send(t),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Text(
                      t,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addAllButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _applyAllActions,
          icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
          label: const Text('إضافة الكل إلى المهام'),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
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
          Text('Liv بيفكر...', style: TextStyle(color: secondaryText(context), fontSize: 13)),
        ],
      ),
    );
  }
}
