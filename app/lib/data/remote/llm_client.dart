import 'dart:math';
import 'package:dio/dio.dart';
import '../../shared/constants.dart';

/// Supported chat backends.
enum LlmProvider {
  anthropic,
  openAiCompatible,
}

/// User-facing authentication/config error for LLM backends.
class LlmAuthException implements Exception {
  final String message;

  const LlmAuthException(this.message);

  @override
  String toString() => message;
}

/// User-facing HTTP error for LLM backend requests.
class LlmHttpException implements Exception {
  final int? statusCode;
  final String message;

  const LlmHttpException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Thin wrapper around Anthropic and OpenAI-compatible chat APIs.
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
  final String _defaultModel;
  final LlmProvider _provider;
  static final _rng = Random();

  LlmClient({
    required String apiKey,
    required LlmProvider provider,
    String? baseUrl,
    String? defaultModel,
    Dio? dio,
  })  : _apiKey = apiKey,
        _provider = provider,
        _baseUrl = _normalizeBaseUrl(
          baseUrl ?? _defaultBaseUrlFor(provider),
        ),
        _defaultModel = (defaultModel != null && defaultModel.trim().isNotEmpty)
            ? defaultModel.trim()
            : _defaultModelFor(provider),
        _dio = dio ?? Dio();

  static LlmProvider resolveProvider({
    required String raw,
    required String apiKey,
    required String baseUrl,
  }) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'anthropic') return LlmProvider.anthropic;
    if (normalized == 'openai' ||
        normalized == 'openai-compatible' ||
        normalized == 'openai_compatible') {
      return LlmProvider.openAiCompatible;
    }

    final lowerApiKey = apiKey.toLowerCase();
    final lowerBaseUrl = baseUrl.toLowerCase();
    if (lowerApiKey.startsWith('sk-ant-') ||
        lowerBaseUrl.contains('anthropic.com')) {
      return LlmProvider.anthropic;
    }
    return LlmProvider.openAiCompatible;
  }

  /// Send a chat completion request and return the assistant's reply.
  ///
  /// On failure, returns a local fallback response instead of throwing.
  Future<String> chat({
    required String systemPrompt,
    required List<LlmMessage> messages,
    String? model,
    int maxTokens = LumaConstants.defaultMaxTokens,
    double temperature = 0.8,
  }) async {
    final resolvedModel =
        (model != null && model.trim().isNotEmpty) ? model.trim() : _defaultModel;

    try {
      switch (_provider) {
        case LlmProvider.anthropic:
          return await _chatAnthropic(
            systemPrompt: systemPrompt,
            messages: messages,
            model: resolvedModel,
            maxTokens: maxTokens,
            temperature: temperature,
          );
        case LlmProvider.openAiCompatible:
          return await _chatOpenAiCompatible(
            systemPrompt: systemPrompt,
            messages: messages,
            model: resolvedModel,
            maxTokens: maxTokens,
            temperature: temperature,
          );
      }
    } on LlmAuthException {
      rethrow;
    } on LlmHttpException {
      rethrow;
    } on DioException catch (e) {
      if (_isHttpFailure(e)) {
        throw LlmHttpException(
          statusCode: e.response?.statusCode,
          message: 'LLM request failed with HTTP ${e.response?.statusCode ?? 'unknown'}.',
        );
      }
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

  Future<String> _chatAnthropic({
    required String systemPrompt,
    required List<LlmMessage> messages,
    required String model,
    required int maxTokens,
    required double temperature,
  }) async {
    if (_apiKey.isEmpty) {
      throw const LlmAuthException('LLM API key is missing.');
    }

    final response = await _dio.post(
      _apiEndpoint('/messages'),
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

    final data = response.data;
    if (data is! Map) return _fallbackReply();
    final content = data['content'];
    if (content is! List || content.isEmpty) return _fallbackReply();

    final first = content.first;
    if (first is! Map) return _fallbackReply();
    final text = first['text'];
    if (text is String && text.trim().isNotEmpty) return text;
    return _fallbackReply();
  }

  Future<String> _chatOpenAiCompatible({
    required String systemPrompt,
    required List<LlmMessage> messages,
    required String model,
    required int maxTokens,
    required double temperature,
  }) async {
    final headers = <String, String>{
      'content-type': 'application/json',
    };
    if (_apiKey.isNotEmpty) {
      headers['authorization'] = 'Bearer $_apiKey';
    }

    try {
      final response = await _dio.post(
        _apiEndpoint('/chat/completions'),
        options: Options(headers: headers),
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages.map((m) => m.toMap()),
          ],
        },
      );

      final text = _extractOpenAiText(response.data);
      if (text == null || text.trim().isEmpty) return _fallbackReply();
      return text;
    } on DioException catch (e) {
      // Older/local Ollama versions may not expose /v1/chat/completions.
      if (e.response?.statusCode == 404 && _looksLikeLocalOllama()) {
        return _chatOllamaNative(
          systemPrompt: systemPrompt,
          messages: messages,
          model: model,
          temperature: temperature,
        );
      }
      rethrow;
    }
  }

  String? _extractOpenAiText(dynamic data) {
    if (data is! Map) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final firstChoice = choices.first;
    if (firstChoice is! Map) return null;
    final message = firstChoice['message'];
    if (message is! Map) return null;
    return _extractMessageContent(message['content']);
  }

  String? _extractMessageContent(dynamic content) {
    if (content is String) {
      return content;
    }
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text'] as String);
        }
      }
      if (buffer.isNotEmpty) {
        return buffer.toString();
      }
    }
    return null;
  }

  Future<String> _chatOllamaNative({
    required String systemPrompt,
    required List<LlmMessage> messages,
    required String model,
    required double temperature,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/chat',
      options: Options(
        headers: {'content-type': 'application/json'},
      ),
      data: {
        'model': model,
        'stream': false,
        'options': {
          'temperature': temperature,
        },
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages.map((m) => m.toMap()),
        ],
      },
    );

    final data = response.data;
    if (data is! Map) return _fallbackReply();
    final message = data['message'];
    if (message is! Map) return _fallbackReply();
    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) return content;
    return _fallbackReply();
  }

  bool _looksLikeLocalOllama() {
    final lower = _baseUrl.toLowerCase();
    return lower.contains('127.0.0.1:11434') ||
        lower.contains('localhost:11434');
  }

  bool _isHttpFailure(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return false;
    return status >= 400 && status < 600;
  }

  String _apiEndpoint(String suffix) {
    if (_hasVersionPrefix(_baseUrl)) {
      return '$_baseUrl$suffix';
    }
    return '$_baseUrl/v1$suffix';
  }

  bool _hasVersionPrefix(String rawBaseUrl) {
    final path = Uri.parse(rawBaseUrl).path.toLowerCase();
    return path.endsWith('/v1') ||
        path.contains('/v1/') ||
        path.endsWith('/v1beta') ||
        path.contains('/v1beta/') ||
        path.endsWith('/v1alpha') ||
        path.contains('/v1alpha/');
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _defaultBaseUrlFor(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.anthropic:
        return 'https://api.anthropic.com';
      case LlmProvider.openAiCompatible:
        return 'https://api.openai.com';
    }
  }

  static String _defaultModelFor(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.anthropic:
        return LumaConstants.defaultModel;
      case LlmProvider.openAiCompatible:
        return 'gpt-4o-mini';
    }
  }
}

class LlmMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const LlmMessage({required this.role, required this.content});

  Map<String, String> toMap() => {'role': role, 'content': content};
}
