import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String model;
  final String provider;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-flash-lite-latest',
    this.provider = 'gemini',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> generateText(String prompt) async {
    if (!isConfigured) {
      throw Exception(
        'محتاج تحط مفتاح API من البروفايل الأول.\n'
        'روح aistudio.google.com/apikey وخذ مفتاح مجاني.',
      );
    }
    final m = model.isEmpty ? 'gemini-flash-lite-latest' : model;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$apiKey',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
    });
    final res = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('Gemini error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }
    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty response from Gemini');
    }
    return (parts[0]['text'] as String?) ?? '';
  }

  Future<String> chat({
    required String userMessage,
    required String context,
    List<Map<String, String>> history = const [],
  }) {
    final previous = history.take(8).map((m) {
      final who = m['role'] == 'user' ? 'مستخدم' : 'Liv';
      return '$who: ${m['text']}';
    }).join('\n');
    return generateText('''
أنت Liv AI — مساعد حياة هادئ، ودود، عملي، مختصر. صوتك مطمئن مش مخيف.
سياق: $context
محادثة: $previous
رسالة: $userMessage
رد بهدوء ووضوح.
إذا اقترحت عادة كويسة اكتب [ADD_GOOD:الاسم]
إذا اقترحت عادة سيئة اكتب [ADD_BAD:الاسم]
إذا اقترحت مهمة اكتب [ADD_TASK:الاسم]
إذا اقترحت حلم اكتب [ADD_DREAM:الاسم]
''');
  }
}
