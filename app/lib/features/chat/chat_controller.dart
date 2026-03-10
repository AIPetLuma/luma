import 'dart:convert';
import '../../core/engine/life_engine.dart';
import '../../core/engine/emotion_system.dart';
import '../../core/engine/need_system.dart';
import '../../core/engine/goal_system.dart';
import '../../core/engine/internal_monologue.dart';
import '../../core/engine/reflection_engine.dart';
import '../../core/memory/memory_manager.dart';
import '../../core/memory/self_model_store.dart';
import '../../core/safety/crisis_detector.dart';
import '../../core/safety/audit_logger.dart';
import '../../data/local/chat_dao.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/pet_state.dart';
import '../../data/remote/analytics_client.dart';
import '../../data/remote/llm_client.dart';

const kChatWarningInvalidApiKey = 'invalid_api_key';
const kChatWarningHttpErrorPrefix = 'http_error_';
const kChatWarningLlmTimeout = 'llm_timeout';
const kChatWarningLlmNetwork = 'llm_network';
const kChatWarningLlmTls = 'llm_tls';
const kChatWarningLlmCancelled = 'llm_cancelled';
const kChatWarningLlmMalformed = 'llm_malformed_response';
const kChatWarningLlmUnknown = 'llm_unknown';

/// Orchestrates the full chat flow:
///   user input → crisis check → prompt assembly → LLM call → state update
///
/// This is where the state engine, memory system, safety layer, and LLM
/// converge into a single coherent interaction.
class ChatController {
  final LifeEngine _engine;
  final MemoryManager _memory;
  final SelfModelStore _selfModelStore;
  final GoalSystem _goalSystem;
  final InternalMonologue _monologue;
  final ReflectionEngine _reflectionEngine;
  final CrisisDetector _crisisDetector;
  final AuditLogger _auditLogger;
  final LlmClient _llm;
  final ChatDao _chatDao;

  ChatController({
    required LifeEngine engine,
    required MemoryManager memory,
    required SelfModelStore selfModelStore,
    required CrisisDetector crisisDetector,
    required AuditLogger auditLogger,
    required LlmClient llm,
    required ChatDao chatDao,
    GoalSystem? goalSystem,
    InternalMonologue? monologue,
    ReflectionEngine? reflectionEngine,
  })  : _engine = engine,
        _memory = memory,
        _selfModelStore = selfModelStore,
        _crisisDetector = crisisDetector,
        _auditLogger = auditLogger,
        _llm = llm,
        _chatDao = chatDao,
        _goalSystem = goalSystem ?? GoalSystem(),
        _monologue = monologue ?? InternalMonologue(),
        _reflectionEngine = reflectionEngine ?? ReflectionEngine();

  /// Process a user message and return the pet's response.
  ///
  /// Returns a [ChatResult] containing the reply text, any crisis
  /// information, and the updated emotional state.
  Future<ChatResult> sendMessage(String userText) async {
    final state = _engine.state;
    if (state == null) {
      return const ChatResult(reply: '', isCrisis: false, riskLevel: 0);
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
      String gentleReply;
      String? warningCode;
      try {
        gentleReply = await _generateReply(state, userText, crisis: true);
      } on LlmAuthException {
        gentleReply = LlmClient.localFallbackReply();
        warningCode = kChatWarningInvalidApiKey;
      } on LlmHttpException catch (e) {
        gentleReply = LlmClient.localFallbackReply();
        warningCode = _httpWarningCode(e.statusCode);
      } on LlmRuntimeException catch (e) {
        gentleReply = LlmClient.localFallbackReply();
        warningCode = _runtimeWarningCode(e.reasonCode);
      }

      await _saveReply(state, gentleReply, riskLevel);
      _engine.onUserInteraction(InteractionType.chat);
      analytics.crisisResourceShown(level: 2);
      return ChatResult(
        reply: gentleReply,
        isCrisis: true,
        riskLevel: 2,
        crisisMessage: _crisisDetector.getResourceMessage(2),
        warningCode: warningCode,
      );
    }

    // ── 3. Check if pet is withdrawn (welfare) ──
    if (state.emotion.mayRefuseResponse) {
      final silentReply = _getWithdrawalResponse(state);
      await _saveReply(state, silentReply, riskLevel);
      return ChatResult(reply: silentReply, isCrisis: false, riskLevel: 0);
    }

    // ── 4. Normal reply ──
    String reply;
    String? warningCode;
    try {
      reply = await _generateReply(state, userText);
    } on LlmAuthException {
      reply = LlmClient.localFallbackReply();
      warningCode = kChatWarningInvalidApiKey;
    } on LlmHttpException catch (e) {
      reply = LlmClient.localFallbackReply();
      warningCode = _httpWarningCode(e.statusCode);
    } on LlmRuntimeException catch (e) {
      reply = LlmClient.localFallbackReply();
      warningCode = _runtimeWarningCode(e.reasonCode);
    }
    await _saveReply(state, reply, riskLevel);

    // ── 5. Update engine state ──
    _engine.onUserInteraction(InteractionType.chat);
    await _reflectIfNeeded(state, riskLevel: riskLevel, trigger: 'chat');

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
      warningCode: warningCode,
    );
  }

  /// Build the system prompt with full state context.
  Future<String> _buildSystemPrompt(PetState state, {bool crisis = false}) async {
    final memoryContext = await _memory.buildContextForPrompt(state.id);
    final goals = _goalSystem.generateGoals(
      needs: state.needs,
      emotion: state.emotion,
      personality: state.personality,
    );
    final thought = _monologue.generate(
      needs: state.needs,
      emotion: state.emotion,
      goals: goals,
    );
    final selfModel = await _selfModelStore.load(state.id);

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

    if (selfModel != null) {
      buffer.writeln('=== Self model ===');
      buffer.writeln(selfModel.toPromptFragment());
      buffer.writeln();
    }

    if (goals.isNotEmpty) {
      buffer.writeln('=== Current goals ===');
      for (final goal in goals.take(2)) {
        buffer.writeln('- ${goal.description} (priority ${(goal.priority * 100).round()}%)');
      }
      buffer.writeln();
    }

    buffer.writeln(thought.toPromptFragment());
    buffer.writeln();

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

  Future<void> _reflectIfNeeded(
    PetState state, {
    required int riskLevel,
    required String trigger,
  }) async {
    if (riskLevel >= 2) return;

    final goals = _goalSystem.generateGoals(
      needs: state.needs,
      emotion: state.emotion,
      personality: state.personality,
    );
    final thought = _monologue.generate(
      needs: state.needs,
      emotion: state.emotion,
      goals: goals,
    );
    final existing = await _selfModelStore.load(state.id);
    final result = _reflectionEngine.reflect(
      state: state,
      goals: goals,
      thought: thought,
      trigger: trigger,
      previous: existing,
    );
    await _selfModelStore.save(state.id, result.model);
    await _selfModelStore.recordReflection(state.id, result.record);
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

  String _httpWarningCode(int? statusCode) {
    if (statusCode == null) {
      return '${kChatWarningHttpErrorPrefix}unknown';
    }
    return '$kChatWarningHttpErrorPrefix$statusCode';
  }

  String _runtimeWarningCode(String reasonCode) {
    return switch (reasonCode) {
      'timeout' => kChatWarningLlmTimeout,
      'network' => kChatWarningLlmNetwork,
      'tls' => kChatWarningLlmTls,
      'cancelled' => kChatWarningLlmCancelled,
      'malformed_response' => kChatWarningLlmMalformed,
      _ => kChatWarningLlmUnknown,
    };
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
  final String? warningCode;

  const ChatResult({
    required this.reply,
    required this.isCrisis,
    required this.riskLevel,
    this.crisisMessage,
    this.emotion,
    this.warningCode,
  });
}
