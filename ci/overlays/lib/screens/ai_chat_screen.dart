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
  Map<String, String>? _pendingAction;
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      AudioService.instance.playLoop('assets/audio/meditation_ambient.mp3', volume: 0.90);
    }
  }

  @override
  void didUpdateWidget(covariant AIChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      AudioService.instance.playLoop('assets/audio/meditation_ambient.mp3', volume: 0.90);
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

  Map<String, String>? _parseAddTag(String reply) {
    final m = RegExp(r'\[ADD_(GOOD|BAD|TASK):([^\]]+)\]').firstMatch(reply);
    if (m == null) return null;
    return {'type': m.group(1)!, 'name': m.group(2)!.trim()};
  }

  String _stripAddTag(String reply) {
    return reply.replaceAll(RegExp(r'\s*\[ADD_(GOOD|BAD|TASK):[^\]]+\]\s*'), '').trim();
  }

  Future<void> _applyPendingAction() async {
    final action = _pendingAction;
    if (action == null) return;
    final state = context.read<AppState>();
    final name = action['name'] ?? '';
    if (name.isEmpty) return;
    try {
      final type = action['type'];
      if (type == 'GOOD') {
        await state.addHabit(name, true);
      } else if (type == 'BAD') {
        await state.addHabit(name, false);
      } else if (type == 'TASK') {
        await state.addWeeklyTask(name);
      }
      if (!mounted) return;
      setState(() {
        _pendingAction = null;
        final msg = type == 'TASK'
            ? 'تمت إضافة "$name" إلى المهام ✓'
            : type == 'BAD'
                ? 'تمت إضافة "$name" إلى العادات السيئة ✓'
                : 'تمت إضافة "$name" إلى العادات الجيدة ✓';
        _messages.add({'role': 'assistant', 'text': msg});
      });
      await _persist();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'مقدرناش نضيف العنصر: $e'});
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? forced]) async {
    final text = (forced ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _input.clear();
      _sending = true;
      _pendingAction = null;
    });
    _scrollToEnd();
    await _persist();
    try {
      final state = context.read<AppState>();
      final reply = await state.ai.chat(
        userMessage: text,
        context: state.aiContext,
        history: _messages
            .where((m) => m['role'] != null)
            .map((m) => {'role': m['role']!, 'text': m['text'] ?? ''})
            .toList(),
      );
      final action = _parseAddTag(reply);
      final clean = _stripAddTag(reply);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': clean});
        _pendingAction = action;
        _sending = false;
      });
      await _persist();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': '⚠️ $e'});
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accent = AppColors.accentFrom(state.profile.accentColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                ..._messages.map((m) {
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: isUser
                            ? accent.withOpacity(0.18)
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.35)),
                    ),
                  );
                }),
                if (_sending)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                if (_pendingAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: const Icon(Icons.add_task, size: 18),
                        label: Text(
                          _pendingAction!['type'] == 'TASK'
                              ? 'إضافة إلى المهام اليومية'
                              : _pendingAction!['type'] == 'BAD'
                                  ? 'إضافة إلى العادات السيئة'
                                  : 'إضافة إلى العادات الجيدة',
                        ),
                        onPressed: _applyPendingAction,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'اسأل Liv...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
