import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';

// Service for OpenRouter API with Chat History support
class OpenRouterChatService {
  OpenRouterChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  
  // Dynamic endpoint based on key type
  String _getEndpoint(String key) {
    if (key.startsWith('sk-proj')) {
      return 'https://api.openai.com/v1/chat/completions';
    }
    return 'https://openrouter.ai/api/v1/chat/completions';
  }

  // List of models to try in order
  List<String> _getModels(String key) {
    if (key.startsWith('sk-proj')) {
      return ['gpt-4o-mini', 'gpt-3.5-turbo'];
    }
    return [
      'openai/gpt-4o-mini',
      'anthropic/claude-3.5-sonnet',
      'meta-llama/llama-3.1-70b-instruct',
    ];
  }

  Future<String> sendScopedMessage({
    required String systemPrompt,
    required String userPrompt,
    /// Prior turns (role/content). System + latest user message are added by this method.
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final String key = ApiKeys.openRouterKey.trim();

    if (key.isEmpty) {
      throw Exception('OpenRouter API key is missing');
    }

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
      {'role': 'user', 'content': userPrompt},
    ];
    
    final endpoint = _getEndpoint(key);
    final models = _getModels(key);

    Object? lastError;
    for (final model in models) {
      try {
        final response = await _client.post(
          Uri.parse(endpoint),
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
          debugPrint('OPENROUTER ERROR ($model): $lastError');
          // If we get a 401, it means the key is rejected, no point in trying other models
          if (response.statusCode == 401) break;
        }
      } catch (e) {
        lastError = e;
        debugPrint('OPENROUTER EXCEPTION ($model): $e');
      }
    }

    throw Exception('All models failed. Last error: $lastError');
  }
}
