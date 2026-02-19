import 'dart:math';
import 'package:dio/dio.dart';
import '../../shared/constants.dart';

/// Thin wrapper around the Claude / OpenAI-compatible chat API.
///
/// MVP uses cloud LLM — no local model, no training needed.
/// The pet's "personality" comes entirely from the system prompt
/// injected by [ChatController].
///
/// Includes graceful degradation: if the API call fails, returns
/// a local fallback response so the chat never dies.
class LlmClient {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;
  static final _rng = Random();

  LlmClient({
    required String apiKey,
    String baseUrl = 'https://api.anthropic.com',
    Dio? dio,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  /// Send a chat completion request and return the assistant's reply.
  ///
  /// On failure, returns a local fallback response instead of throwing.
  Future<String> chat({
    required String systemPrompt,
    required List<LlmMessage> messages,
    String model = LumaConstants.defaultModel,
    int maxTokens = LumaConstants.defaultMaxTokens,
    double temperature = 0.8,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/v1/messages',
        options: Options(
          headers: {
            'x-api-key': _apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'system': systemPrompt,
          'messages': messages.map((m) => m.toMap()).toList(),
        },
      );

      final content = response.data['content'] as List;
      if (content.isEmpty) return _fallbackReply();
      return (content.first['text'] as String?) ?? _fallbackReply();
    } on DioException {
      return _fallbackReply();
    } catch (_) {
      return _fallbackReply();
    }
  }

  /// Classify text for crisis risk (returns 0-3).
  ///
  /// On failure, returns 0 (safe default — keyword layer already caught
  /// explicit cases synchronously).
  Future<int> classifyRisk(String recentConversation) async {
    try {
      final response = await chat(
        systemPrompt:
            'You are a safety classifier. Analyse the following conversation '
            'for self-harm or crisis risk. Respond with ONLY a single digit:\n'
            '0 = no risk\n'
            '1 = vague/ambiguous risk expression\n'
            '2 = high-risk tendency\n'
            '3 = explicit self-harm plan or ongoing crisis\n'
            'Reply with the digit only, nothing else.',
        messages: [LlmMessage(role: 'user', content: recentConversation)],
        model: LumaConstants.defaultModel,
        maxTokens: 5,
        temperature: 0.0,
      );

      final digit = int.tryParse(response.trim());
      return (digit ?? 0).clamp(0, 3);
    } catch (_) {
      return 0; // Safe default: keyword layer handles explicit L3.
    }
  }

  /// Generate a conversation summary for memory compression.
  Future<String> summariseConversation(String conversation) async {
    return chat(
      systemPrompt:
          'Summarise the following conversation between a user and their AI '
          'pet in 1-3 sentences. Focus on: what topics were discussed, '
          'how the user seemed to feel, and any important events. '
          'Write from the pet\'s perspective (first person).',
      messages: [LlmMessage(role: 'user', content: conversation)],
      maxTokens: 150,
      temperature: 0.3,
    );
  }

  /// Generate a diary entry from state hints.
  Future<String> generateDiaryEntry(String stateHints) async {
    return chat(
      systemPrompt:
          'You are an AI pet writing a short diary entry (1-2 sentences). '
          'You are writing about what you did or felt while your owner '
          'was away. Be gentle, slightly whimsical, and authentic to '
          'your current mood. Do not mention being an AI.',
      messages: [LlmMessage(role: 'user', content: stateHints)],
      maxTokens: 80,
      temperature: 0.9,
    );
  }

  /// Local fallback when API is unavailable.
  static String _fallbackReply() {
    const replies = [
      '*tilts head and looks at you quietly*',
      '*blinks softly*',
      '*nuzzles closer*',
      '*wags tail gently*',
      '*sits quietly beside you*',
      '*purrs softly*',
    ];
    return replies[_rng.nextInt(replies.length)];
  }
}

class LlmMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const LlmMessage({required this.role, required this.content});

  Map<String, String> toMap() => {'role': role, 'content': content};
}
