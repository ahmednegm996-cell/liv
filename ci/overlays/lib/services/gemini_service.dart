import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  static const List<String> freeGeminiModels = [
    'gemini-flash-lite-latest',
    'gemini-flash-latest',
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
  ];

  static Future<void> _chain = Future.value();
  static DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);
  static int _consecutive429 = 0;

  static Duration get _minGap {
    if (_consecutive429 >= 3) return const Duration(seconds: 18);
    if (_consecutive429 >= 1) return const Duration(seconds: 8);
    return const Duration(seconds: 2);
  }

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final c = Completer<T>();
    _chain = _chain.then((_) async {
      final gap = _minGap - DateTime.now().difference(_lastCall);
      if (gap > Duration.zero) await Future.delayed(gap);
      try {
        final r = await job();
        _lastCall = DateTime.now();
        _consecutive429 = 0;
        c.complete(r);
      } catch (e) {
        _lastCall = DateTime.now();
        c.completeError(e);
      }
    });
    return c.future;
  }

  Future<String> generateText(String prompt) {
    if (!isConfigured) {
      throw Exception(
        'محتاج تحط مفتاح API من البروفايل الأول.\n'
        'روح aistudio.google.com/apikey وخذ مفتاح مجاني.',
      );
    }
    return _enqueue(() => _generateWithRetry(prompt));
  }

  Future<String> _generateWithRetry(String prompt, {int attempt = 0}) async {
    try {
      if (provider == 'grok' || provider == 'groq') {
        return await _openAiCompatible(prompt);
      }
      return await _gemini(prompt);
    } catch (e) {
      final msg = e.toString();
      final is429 = msg.contains('429') ||
          msg.contains('حد الطلبات') ||
          msg.contains('RESOURCE_EXHAUSTED') ||
          msg.contains('quota') ||
          msg.contains('exceeded');
      final retriable = is429 ||
          msg.contains('Timeout') ||
          msg.contains('وقت طويل');
      if (is429) _consecutive429++;
      if (retriable && attempt < 3) {
        await Future.delayed(Duration(seconds: 2 + attempt * 3));
        return _generateWithRetry(prompt, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  Future<String> _gemini(String prompt) async {
    final models = [model, ...freeGeminiModels.where((m) => m != model)];
    Exception? last;
    for (final m in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$apiKey',
        );
        final body = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
        };
        final res = await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
            .timeout(const Duration(seconds: 45));
        if (res.statusCode == 429) {
          throw Exception('حد الطلبات (429). استنى دقيقة.');
        }
        if (res.statusCode != 200) {
          throw Exception('Gemini ${res.statusCode}: ${res.body}');
        }
        final data = jsonDecode(res.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null || text.toString().trim().isEmpty) {
          throw Exception('رد فاضي من Gemini');
        }
        return text.toString().trim();
      } catch (e) {
        last = e is Exception ? e : Exception('$e');
        continue;
      }
    }
    throw last ?? Exception('كل الموديلات فشلت');
  }

  Future<String> _openAiCompatible(String prompt) async {
    final base = provider == 'grok'
        ? 'https://api.x.ai/v1/chat/completions'
        : 'https://api.groq.com/openai/v1/chat/completions';
    final uri = Uri.parse(base);
    final body = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    };
    final res = await http
        .post(uri, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        }, body: jsonEncode(body))
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('${provider} ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    final text = data['choices']?[0]?['message']?['content'];
    return (text ?? '').toString().trim();
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
لو المستخدم طلب عادة كويسة او عادة وحشة او مهمة بشكل واضح، اضف في اخر الرد سطر واحد فقط بالصيغة:
[ADD_GOOD:اسم العادة]
او
[ADD_BAD:اسم العادة]
او
[ADD_TASK:عنوان المهمة]
من غير شرح بعد السطر ده.
''');
  }

  Future<String> personalityInsight({required String profileSummary}) {
    return generateText(
      'انت محلل شخصية هادئ وواقعي لتطبيق Liv.\n'
      'بناء على ملخص المستخدم التالي اكتب تحليل شخصية مختصر وواضح بالعامية المصرية (8-12 سطر):\n'
      '- نمط الشخصية العام\n'
      '- نقاط القوة\n'
      '- نقاط تحتاج تحسين\n'
      '- عادة واحدة مقترحة\n'
      '- جملة تحفيزية قصيرة\n\n'
      'الملخص:\n' + profileSummary + '\n\n'
      'لا تستخدم Markdown. كن صادق ومفيد.',
    );
  }
}
