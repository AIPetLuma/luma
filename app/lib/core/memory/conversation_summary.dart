import '../../data/models/chat_message.dart';

/// Utility to format conversation history for LLM summarisation.
class ConversationSummary {
  /// Convert a list of messages into a readable transcript string.
  static String toTranscript(List<ChatMessage> messages) {
    return messages
        .map((m) => '${m.role == ChatRole.user ? "User" : "Pet"}: ${m.content}')
        .join('\n');
  }

  /// Estimate the token count of a text (rough: 1 token ≈ 4 chars).
  static int estimateTokens(String text) => (text.length / 4).ceil();
}
