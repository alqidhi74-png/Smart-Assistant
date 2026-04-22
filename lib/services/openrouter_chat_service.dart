import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';

class OpenRouterChatService {
  OpenRouterChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  static const List<String> _models = [
    'openai/gpt-4o-mini',
    'anthropic/claude-3.5-sonnet',
    'meta-llama/llama-3.1-70b-instruct',
  ];

  Future<String> sendScopedMessage({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final key = ApiKeys.openRouterKey.trim();
    if (key.isEmpty || key == 'PUT_OPENROUTER_KEY_HERE') {
      throw Exception('OpenRouter API key is missing');
    }

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
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.2,
          }),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('[$model] HTTP ${response.statusCode}: ${response.body}');
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = decoded['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw Exception('[$model] Empty choices');
        }
        final message = choices.first['message'] as Map<String, dynamic>?;
        final text = message?['content']?.toString().trim() ?? '';
        if (text.isEmpty) {
          throw Exception('[$model] Empty content');
        }
        return text;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(lastError ?? 'OpenRouter request failed');
  }
}
