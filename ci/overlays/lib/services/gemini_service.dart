import 'dart:convert';
import 'package:http/http.dart' as http;

/// خدمة الذكاء الاصطناعي — Gemini أولاً، مع بدائل OpenAI-compatible (xAI / Groq).
class GeminiService {
  // مفاتيح مجانية تتحط مرة واحدة. ممكن تسيبها فاضية؛ التطبيق يشتغل offline.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String xaiApiKey = String.fromEnvironment(
    'XAI_API_KEY',
    defaultValue: '',
  );
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  // موديلات Gemini بالترتيب (من الأحدث للأقدم المتاح مجانًا)
  static const _geminiModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-pro',
  ];

  bool get isConfigured =>
      geminiApiKey.isNotEmpty || xaiApiKey.isNotEmpty || groqApiKey.isNotEmpty;

  Future<String>? _queue;

  Future<String> _enqueue(Future<String> Function() job) {
    final prev = _queue;
    final next = () async {
      if (prev != null) {
        try {
          await prev;
        } catch (_) {}
      }
      return job();
    }();
    _queue = next;
    return next;
  }

  Future<String> generateText(String prompt) {
    if (!isConfigured) {
      return Future.value(
        'الـ AI مش متظبط. ضيف GEMINI_API_KEY (مجاني من Google AI Studio).',
      );
    }
    return _enqueue(() => _generateWithRetry(prompt));
  }

  Future<String> _generateWithRetry(String prompt, {int attempt = 0}) async {
    try {
      if (geminiApiKey.isNotEmpty) {
        return await _gemini(prompt);
      }
      return await _openAiCompatible(prompt);
    } catch (e) {
      final msg = e.toString();
      final retryable = msg.contains('429') ||
          msg.contains('RESOURCE_EXHAUSTED') ||
          msg.contains('quota') ||
          msg.contains('rate');
      if (retryable && attempt < 2) {
        await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
        return _generateWithRetry(prompt, attempt: attempt + 1);
      }
      if (geminiApiKey.isNotEmpty &&
          (xaiApiKey.isNotEmpty || groqApiKey.isNotEmpty)) {
        try {
          return await _openAiCompatible(prompt);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<String> _gemini(String prompt) async {
    Object? lastErr;
    for (final m in _geminiModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent',
        ).replace(queryParameters: {'key': geminiApiKey});
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.7,
                  'maxOutputTokens': 1024,
                }
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (res.statusCode == 404) {
          lastErr = Exception('model $m not found');
          continue;
        }
        if (res.statusCode != 200) {
          throw Exception('Gemini ${res.statusCode}: ${res.body}');
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List? ?? [];
        if (candidates.isEmpty) {
          final block = data['promptFeedback']?['blockReason'];
          throw Exception(block != null ? 'اتحظر الرد: $block' : 'مفيش رد');
        }
        final parts = candidates[0]['content']?['parts'] as List? ?? [];
        final text = parts.map((p) => p['text'] ?? '').join().trim();
        if (text.isEmpty) throw Exception('رد فاضي');
        return text;
      } catch (e) {
        lastErr = e;
        final s = e.toString();
        if (s.contains('404') || s.contains('not found')) continue;
        rethrow;
      }
    }
    throw Exception('Gemini فشل: $lastErr');
  }

  Future<String> _openAiCompatible(String prompt) async {
    final useXai = xaiApiKey.isNotEmpty;
    final key = useXai ? xaiApiKey : groqApiKey;
    final url = useXai
        ? 'https://api.x.ai/v1/chat/completions'
        : 'https://api.groq.com/openai/v1/chat/completions';
    final model = useXai ? 'grok-2-latest' : 'llama-3.3-70b-versatile';
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('AI ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List? ?? [];
    if (choices.isEmpty) throw Exception('مفيش رد');
    final text = (choices[0]['message']?['content'] ?? '').toString().trim();
    if (text.isEmpty) throw Exception('رد فاضي');
    return text;
  }

  Future<String> testConnection() =>
      generateText('Reply with one word only: OK');

  Future<List<String>> generateDreamSteps({
    required String dreamTitle,
    String? dreamDescription,
  }) async {
    final text = await generateText('''
حلم المستخدم: $dreamTitle
${dreamDescription ?? ''}
اكتب 5-8 خطوات عملية قصيرة بالعربي العامي المصري. سطر لكل خطوة. بدون ترقيم معقد.
''');
    return text
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[\-\*\d\.\)\s]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .take(8)
        .toList();
  }

  Future<String> weeklyMeeting({required String weeklySummary}) =>
      generateText('''
ميتنج أسبوعي. الملخص:
$weeklySummary
باختصار: 1) إنجاز 2) مشكلة 3) خطوة واحدة للأسبوع الجاي.
''');

  Future<String> dailyMeeting({required String dailySummary}) =>
      generateText('''
ميتنج سريع آخر اليوم:
$dailySummary
في 4 أسطر: اللي اتعمل، اللي اتأجل، حاجة واحدة بكرة.
''');

  Future<String> analyzeHabitImpact({
    required String habitName,
    required bool isGood,
    required int currentStreakDays,
  }) =>
      generateText(
        'عادة ${isGood ? 'كويسة' : 'وحشة'}: "$habitName" — $currentStreakDays يوم. '
        'تأثير 3-12 شهر + نصيحة. 5 جمل.',
      );

  Future<Map<String, dynamic>> generateStarterPlan({
    required Map<String, String> answers,
  }) async {
    final context =
        answers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    final text = await generateText('''
بيانات مستخدم Liv:
$context
JSON فقط:
{"good_habits":[".."],"bad_habits":[".."],"weekly_tasks":[".."],"dream_title":"..","dream_description":".."}
''');
    final cleaned = text
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'^```\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```\$', multiLine: true), '')
        .trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    final jsonStr = (start >= 0 && end > start)
        ? cleaned.substring(start, end + 1)
        : cleaned;
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('خطة البداية غير مفهومة.');
    }
    return decoded;
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
[ADD_GOOD:اسم]
او [ADD_BAD:اسم]
او [ADD_TASK:عنوان]
من غير شرح بعد السطر.
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
