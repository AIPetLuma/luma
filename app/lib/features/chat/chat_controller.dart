import 'dart:convert';
import '../../core/engine/life_engine.dart';
import '../../core/engine/need_system.dart';
import '../../core/engine/emotion_system.dart';
import '../../core/engine/behavior_decider.dart';
import '../../core/memory/memory_manager.dart';
import '../../core/safety/crisis_detector.dart';
import '../../core/safety/audit_logger.dart';
import '../../data/local/chat_dao.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/pet_state.dart';
import '../../data/remote/analytics_client.dart';
import '../../data/remote/llm_client.dart';
import '../../shared/constants.dart';

/// Orchestrates the full chat flow:
///   user input → crisis check → prompt assembly → LLM call → state update
///
/// This is where the state engine, memory system, safety layer, and LLM
/// converge into a single coherent interaction.
class ChatController {
  final LifeEngine _engine;
  final MemoryManager _memory;
  final CrisisDetector _crisisDetector;
  final AuditLogger _auditLogger;
  final LlmClient _llm;
  final ChatDao _chatDao;

  ChatController({
    required LifeEngine engine,
    required MemoryManager memory,
    required CrisisDetector crisisDetector,
    required AuditLogger auditLogger,
    required LlmClient llm,
    required ChatDao chatDao,
  })  : _engine = engine,
        _memory = memory,
        _crisisDetector = crisisDetector,
        _auditLogger = auditLogger,
        _llm = llm,
        _chatDao = chatDao;

  /// Process a user message and return the pet's response.
  ///
  /// Returns a [ChatResult] containing the reply text, any crisis
  /// information, and the updated emotional state.
  Future<ChatResult> sendMessage(String userText) async {
    final state = _engine.state;
    if (state == null) {
      return ChatResult(reply: '', isCrisis: false, riskLevel: 0);
    }

    // ── 1. Save user message ──
    final userMsg = ChatMessage(
      petId: state.id,
      role: ChatRole.user,
      content: userText,
      emotionSnapshot: jsonEncode(state.emotion.toMap()),
      createdAt: DateTime.now(),
    );
    await _chatDao.insertMessage(userMsg);

    // ── 2. Crisis detection ──
    final recentMessages = await _chatDao.getRecentMessages(state.id, limit: 6);
    final riskLevel = _crisisDetector.detect(userText, recentMessages);

    final analytics = AnalyticsClient.instance;

    if (riskLevel > 0) {
      analytics.riskSignalDetected(
        level: riskLevel,
        source: riskLevel >= 2 ? 'keyword+context' : 'keyword',
      );
      analytics.riskLevelAssigned(level: riskLevel);
    }

    if (riskLevel >= 2) {
      await _auditLogger.logCrisis(
        riskLevel: riskLevel,
        triggerText: userText,
        context: recentMessages.map((m) => m.content).join('\n'),
      );
    }

    // L3 crisis — block normal reply, show emergency resources only.
    if (riskLevel == 3) {
      _engine.onHarmDetected();
      analytics.crisisResourceShown(level: 3);
      return ChatResult(
        reply: '',
        isCrisis: true,
        riskLevel: 3,
        crisisMessage: _crisisDetector.getResourceMessage(3),
      );
    }

    // L2 crisis — reply with care + resource card.
    if (riskLevel == 2) {
      final gentleReply = await _generateReply(state, userText, crisis: true);
      _engine.onUserInteraction(InteractionType.chat);
      analytics.crisisResourceShown(level: 2);
      return ChatResult(
        reply: gentleReply,
        isCrisis: true,
        riskLevel: 2,
        crisisMessage: _crisisDetector.getResourceMessage(2),
      );
    }

    // ── 3. Check if pet is withdrawn (welfare) ──
    if (state.emotion.mayRefuseResponse) {
      final silentReply = _getWithdrawalResponse(state);
      await _saveReply(state, silentReply, riskLevel);
      return ChatResult(reply: silentReply, isCrisis: false, riskLevel: 0);
    }

    // ── 4. Normal reply ──
    final reply = await _generateReply(state, userText);
    await _saveReply(state, reply, riskLevel);

    // ── 5. Update engine state ──
    _engine.onUserInteraction(InteractionType.chat);

    // ── 6. L1 soft resource hint ──
    String? softHint;
    if (riskLevel == 1) {
      softHint = _crisisDetector.getResourceMessage(1);
      analytics.crisisResourceShown(level: 1);
      await _auditLogger.logCrisis(
        riskLevel: 1,
        triggerText: userText,
        context: '',
      );
    }

    return ChatResult(
      reply: reply,
      isCrisis: false,
      riskLevel: riskLevel,
      crisisMessage: softHint,
      emotion: state.emotion.label,
    );
  }

  /// Build the system prompt with full state context.
  Future<String> _buildSystemPrompt(PetState state, {bool crisis = false}) async {
    final memoryContext = await _memory.buildContextForPrompt(state.id);

    final buffer = StringBuffer();

    buffer.writeln('You are "${state.name}", an AI pet companion.');
    buffer.writeln('You are NOT a human. You are a small, gentle creature '
        'with your own feelings and needs.');
    buffer.writeln('You were born on ${state.birthday.toIso8601String().substring(0, 10)}. '
        'You are ${state.ageDays} days old.');
    buffer.writeln();

    // Personality.
    buffer.writeln(state.personalityPrompt);
    buffer.writeln();

    // Current emotional state.
    buffer.writeln('=== Your current state ===');
    buffer.writeln(state.emotion.promptDescription);
    buffer.writeln('Loneliness: ${(state.needs.loneliness * 100).round()}%');
    buffer.writeln('Curiosity: ${(state.needs.curiosity * 100).round()}%');
    buffer.writeln('Fatigue: ${(state.needs.fatigue * 100).round()}%');
    buffer.writeln();

    // Reunion context.
    final minutesApart = state.minutesSinceLastActive;
    if (minutesApart > 60) {
      final hours = (minutesApart / 60).round();
      buffer.writeln('Your owner was away for about $hours hours. '
          'React naturally to this — you might have missed them.');
    }
    buffer.writeln();

    // Memory context.
    if (memoryContext.isNotEmpty) {
      buffer.writeln(memoryContext);
      buffer.writeln();
    }

    // Behaviour rules.
    buffer.writeln('=== Behaviour rules ===');
    buffer.writeln('- Never claim to be human. If asked, say you are an AI pet.');
    buffer.writeln('- Match reply length to your energy: tired → short, '
        'excited → longer.');
    buffer.writeln('- You can ask questions, be curious, or stay quiet.');
    buffer.writeln('- If you are feeling withdrawn, it is okay to give '
        'very brief answers or say you need space.');

    if (crisis) {
      buffer.writeln('- IMPORTANT: The user may be going through a difficult '
          'time. Be gentle, validating, and supportive. Do NOT give advice. '
          'Do NOT minimise their feelings. Gently acknowledge their pain.');
    }

    return buffer.toString();
  }

  Future<String> _generateReply(
    PetState state,
    String userText, {
    bool crisis = false,
  }) async {
    final systemPrompt = await _buildSystemPrompt(state, crisis: crisis);
    final recentMessages = await _chatDao.getRecentMessages(state.id, limit: 10);

    final llmMessages = <LlmMessage>[];
    for (final m in recentMessages) {
      llmMessages.add(LlmMessage(
        role: m.role == ChatRole.user ? 'user' : 'assistant',
        content: m.content,
      ));
    }
    // Add the current user message.
    llmMessages.add(LlmMessage(role: 'user', content: userText));

    final emotionSys = EmotionSystem();
    return _llm.chat(
      systemPrompt: systemPrompt,
      messages: llmMessages,
      maxTokens: emotionSys.suggestedMaxTokens(state.emotion),
      temperature: emotionSys.suggestedTemperature(state.personality),
    );
  }

  Future<void> _saveReply(PetState state, String reply, int riskLevel) async {
    await _chatDao.insertMessage(ChatMessage(
      petId: state.id,
      role: ChatRole.pet,
      content: reply,
      emotionSnapshot: jsonEncode(state.emotion.toMap()),
      riskLevel: riskLevel,
      createdAt: DateTime.now(),
    ));
  }

  String _getWithdrawalResponse(PetState state) {
    // The pet is hurt/withdrawn — minimal or no response.
    final responses = [
      '...',
      '*turns away quietly*',
      '*stays silent*',
      '*curls up and doesn\'t respond*',
    ];
    return responses[DateTime.now().second % responses.length];
  }

  /// Call when the conversation session ends (app backgrounded, etc.)
  /// to compress the conversation into L2 memory.
  Future<void> endSession() async {
    final state = _engine.state;
    if (state == null) return;

    final messages = await _chatDao.getRecentMessages(state.id, limit: 30);
    await _memory.compressConversation(state.id, messages);
  }
}

class ChatResult {
  final String reply;
  final bool isCrisis;
  final int riskLevel;
  final String? crisisMessage;
  final String? emotion;

  const ChatResult({
    required this.reply,
    required this.isCrisis,
    required this.riskLevel,
    this.crisisMessage,
    this.emotion,
  });
}
