import '../../data/local/memory_dao.dart';
import '../../data/models/memory_entry.dart';
import '../../data/models/chat_message.dart';
import '../../data/remote/llm_client.dart';
import '../../shared/constants.dart';

/// Three-layer memory system that gives Luma persistent identity.
///
/// - L1 (working): raw conversation turns — in-memory only.
/// - L2 (short-term): conversation summaries — stored 30 days.
/// - L3 (long-term): key events & user profile — permanent.
///
/// "It remembers every day you spent together" — this is what makes
/// the relationship irreplaceable.
class MemoryManager {
  final MemoryDao _dao;
  final LlmClient _llm;

  MemoryManager({required MemoryDao dao, required LlmClient llm})
      : _dao = dao,
        _llm = llm;

  /// Build a context string for system prompt injection.
  ///
  /// Combines L3 (permanent) + recent L2 (summaries), staying within
  /// [LumaConstants.memoryContextMaxTokens] (rough estimate).
  Future<String> buildContextForPrompt(String petId) async {
    final longTerm = await _dao.getLongTerm(petId);
    final shortTerm = await _dao.getRecentShortTerm(petId, limit: 5);

    final buffer = StringBuffer();

    if (longTerm.isNotEmpty) {
      buffer.writeln('=== Important memories ===');
      for (final m in longTerm) {
        buffer.writeln('- ${m.content}');
      }
    }

    if (shortTerm.isNotEmpty) {
      buffer.writeln('=== Recent conversations ===');
      for (final m in shortTerm) {
        buffer.writeln('- ${m.content}');
      }
    }

    // Rough truncation to stay within token budget.
    final text = buffer.toString();
    if (text.length > LumaConstants.memoryContextMaxTokens * 4) {
      return text.substring(0, LumaConstants.memoryContextMaxTokens * 4);
    }
    return text;
  }

  /// Compress a finished conversation into an L2 summary.
  Future<void> compressConversation(
    String petId,
    List<ChatMessage> messages,
  ) async {
    if (messages.length < 4) return; // Too short to summarise.

    final transcript = messages
        .map((m) => '${m.role.name}: ${m.content}')
        .join('\n');

    final summary = await _llm.summariseConversation(transcript);

    await _dao.insert(MemoryEntry(
      petId: petId,
      level: MemoryLevel.shortTerm,
      content: summary,
      emotionTag: messages.last.emotionSnapshot,
      importance: 0.5,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(days: LumaConstants.shortTermMemoryDays),
      ),
    ));
  }

  /// Promote a significant event to L3 (permanent memory).
  Future<void> recordKeyEvent(
    String petId, {
    required String description,
    double importance = 0.8,
    String? emotionTag,
  }) async {
    await _dao.insert(MemoryEntry(
      petId: petId,
      level: MemoryLevel.longTerm,
      content: description,
      emotionTag: emotionTag,
      importance: importance,
      createdAt: DateTime.now(),
    ));
  }

  /// Housekeeping: remove expired L2 memories.
  Future<void> cleanExpired() async {
    await _dao.deleteExpired();
  }
}
