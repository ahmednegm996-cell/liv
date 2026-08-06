import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/gemini_service.dart';
import '../services/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _messages = <Map<String, String>>[];
  final _gemini = GeminiService();
  bool _loading = false;

  final _suggestions = [
    'Give me 10 steps to start a morning routine',
    'How can I build a reading habit?',
    'Suggest a healthy daily plan',
    'Motivate me for today',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = L10n.of(state.profile.locale);
    final accent = AppColors.accentFrom(state.profile.accentColor);

    return Scaffold(
      appBar: AppBar(title: Text(t.ai)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (_loading && i == _messages.length) {
                  return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                }
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? accent.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) => ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _ctrl.text = s;
                    _send();
                  },
                )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: state.profile.locale == 'en' ? 'Ask Liv AI...' : 'اسأل مساعد Liv...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                Gaps.w8,
                IconButton.filled(
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _ctrl.clear();
      _loading = true;
    });
    final reply = await _gemini.chat(text);
    setState(() {
      _messages.add({'role': 'assistant', 'text': reply});
      _loading = false;
    });
  }
}
