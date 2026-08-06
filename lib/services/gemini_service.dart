import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Replace with your own free Gemini API key from Google AI Studio
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const _model = 'gemini-1.5-flash';

  Future<String> chat(String prompt, {String system = ''}) async {
    if (_apiKey.isEmpty) {
      return 'AI is offline (add GEMINI_API_KEY). Meanwhile: focus on one small step today.';
    }
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );
      final body = {
        'contents': [
          if (system.isNotEmpty)
            {
              'role': 'user',
              'parts': [
                {'text': system}
              ]
            },
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      };
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (res.statusCode != 200) return 'AI error: ${res.statusCode}';
      final data = jsonDecode(res.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text?.toString() ?? 'No response';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  String personalityInsight(UserProfileLike p) {
    final age = p.birthDate != null ? DateTime.now().difference(p.birthDate!).inDays ~/ 365 : 0;
    return 'Level ${p.level}, ${p.points} pts, age ~$age. Keep going!';
  }
}

// lightweight duck type to avoid circular import
abstract class UserProfileLike {
  int get level;
  int get points;
  DateTime? get birthDate;
}
