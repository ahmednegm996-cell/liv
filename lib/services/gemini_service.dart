import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal GeminiService for Phase 8H+ compatibility.
/// Matches only the call sites used by AppState.ai and AiChatScreen.
class GeminiService {
  final String apiKey;
  final String model;
  final String provider;

  GeminiService({
    required this.apiKey,
    required this.model,
    this.provider = 'gemini',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> chat({
    required String userMessage,
    required String context,
    required List<Map<String, String>> history,
  }) async {
    if (!isConfigured) {
      return 'حط API Key من صفحة البروفايل عشان Liv AI يشتغل.';
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      final role = (m['role'] == 'assistant') ? 'model' : 'user';
      final text = m['text'] ?? m['content'] ?? '';
      if (text.isEmpty) continue;
      contents.add({
        'role': role,
        'parts': [
          {'text': text}
        ],
      });
    }
    if (contents.isEmpty || (contents.last['role'] as String?) != 'user') {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      });
    }

    final systemHint = context.isEmpty
        ? 'You are Liv, a helpful Arabic/English productivity coach.'
        : 'You are Liv, a helpful Arabic/English productivity coach.\nContext:\n$context';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemHint}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts.first['text']?.toString() ?? '';
            if (text.isNotEmpty) return text;
          }
        }
        return 'مفيش رد من النموذج.';
      }
      return 'خطأ من Gemini (${res.statusCode}): ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}';
    } catch (e) {
      return 'فشل الاتصال: $e';
    }
  }
}
