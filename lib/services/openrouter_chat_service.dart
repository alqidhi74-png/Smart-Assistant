import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';

// Service for OpenRouter API with Chat History support
class OpenRouterChatService {
  OpenRouterChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // List of models to try in order (Fallback system)
  final List<String> _models = [
    'openai/gpt-4o-mini',
    'anthropic/claude-3.5-sonnet',
    'meta-llama/llama-3.1-70b-instruct',
  ];

  Future<String> sendScopedMessage({
    required String systemPrompt,
    required String userPrompt,
    /// Prior turns (role/content). System + latest user message are added by this method.
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final key = ApiKeys.openRouterKey.trim();

    if (key.isEmpty || key == 'PUT_OPENROUTER_KEY_HERE') {
      throw Exception('OpenRouter API key is missing');
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
      {'role': 'user', 'content': userPrompt},
    ];

    Object? lastError;
    for (final model in _models) {
      try {
        final response = await _client.post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://smart-assistant.local',
            'X-Title': 'smart_assistant',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.2,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'] ?? '';
        } else {
          lastError = 'Status ${response.statusCode}: ${response.body}';
          print('OPENROUTER ERROR ($model): $lastError');
        }
      } catch (e) {
        lastError = e;
        print('OPENROUTER EXCEPTION ($model): $e');
      }
    }

    throw Exception('All models failed. Last error: $lastError');
  }
}
