import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/life_engine.dart';
import 'package:luma/core/engine/need_system.dart';
import 'package:luma/core/engine/reflection_engine.dart';
import 'package:luma/core/identity/self_model.dart';
import 'package:luma/core/memory/memory_manager.dart';
import 'package:luma/core/memory/self_model_store.dart';
import 'package:luma/core/safety/crisis_detector.dart';
import 'package:luma/core/safety/audit_logger.dart';
import 'package:luma/data/local/chat_dao.dart';
import 'package:luma/data/local/memory_dao.dart';
import 'package:luma/data/models/chat_message.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/memory_entry.dart';
import 'package:luma/data/remote/llm_client.dart';
import 'package:luma/features/chat/chat_controller.dart';

class FakeChatDao extends ChatDao {
  final List<ChatMessage> _messages = [];

  @override
  Future<int> insertMessage(ChatMessage msg) async {
    _messages.add(msg);
    return _messages.length;
  }

  @override
  Future<List<ChatMessage>> getRecentMessages(
    String petId, {
    int limit = 20,
  }) async {
    final filtered = _messages.where((m) => m.petId == petId).toList();
    final slice = filtered.length > limit
        ? filtered.sublist(filtered.length - limit)
        : filtered;
    return slice;
  }
}

class FakeMemoryDao extends MemoryDao {
  final List<MemoryEntry> _entries = [];

  @override
  Future<int> insert(MemoryEntry entry) async {
    _entries.add(entry);
    return _entries.length;
  }

  @override
  Future<List<MemoryEntry>> getLongTermByPrefix(
    String petId,
    String prefix, {
    int limit = 5,
  }) async {
    return _entries
        .where(
          (e) =>
              e.petId == petId &&
              e.level == MemoryLevel.longTerm &&
              e.content.startsWith(prefix),
        )
        .take(limit)
        .toList();
  }
}

class FakeSelfModelStore extends SelfModelStore {
  FakeSelfModelStore({required MemoryDao dao}) : super(dao: dao);

  bool saveCalled = false;
  bool recordCalled = false;

  @override
  Future<void> save(String petId, SelfModel model) async {
    saveCalled = true;
  }

  @override
  Future<void> recordReflection(String petId, ReflectionRecord record) async {
    recordCalled = true;
  }
}

class FakeAuditLogger extends AuditLogger {
  bool crisisLogged = false;

  @override
  Future<void> logCrisis({
    required int riskLevel,
    required String triggerText,
    required String context,
  }) async {
    crisisLogged = true;
  }
}

class FakeLifeEngine extends LifeEngine {
  final PetState _fakeState;
  bool harmDetectedCalled = false;

  FakeLifeEngine(this._fakeState) : super();

  @override
  PetState? get state => _fakeState;

  @override
  void onHarmDetected() {
    harmDetectedCalled = true;
  }

  @override
  void onUserInteraction(InteractionType type) {}
}

class FakeLlmClient extends LlmClient {
  FakeLlmClient()
      : super(
          apiKey: 'test',
          provider: LlmProvider.openAiCompatible,
          baseUrl: 'http://localhost',
        );

  bool chatCalled = false;

  @override
  Future<String> chat({
    required String systemPrompt,
    required List<LlmMessage> messages,
    String? model,
    int maxTokens = 0,
    double temperature = 0,
  }) async {
    chatCalled = true;
    throw StateError('LLM should not be called for L3 crisis.');
  }
}

PetState _makePet() {
  final now = DateTime(2026, 3, 10, 12, 0, 0);
  return PetState(
    id: 'pet-crisis-1',
    name: 'Sisi',
    birthday: now.subtract(const Duration(days: 3)),
    personality: {'openness': 0.7},
    needs: Needs(),
    emotion: Emotion(valence: 0.1, arousal: 0.2),
    lastActiveAt: now,
    createdAt: now.subtract(const Duration(days: 3)),
    updatedAt: now,
  );
}

void main() {
  test('L3 crisis blocks autonomous reply and reflection', () async {
    final pet = _makePet();
    final lifeEngine = FakeLifeEngine(pet);
    final chatDao = FakeChatDao();
    final memoryDao = FakeMemoryDao();
    final selfModelStore = FakeSelfModelStore(dao: memoryDao);
    final memoryManager = MemoryManager(
      dao: memoryDao,
      llm: FakeLlmClient(),
    );
    final auditLogger = FakeAuditLogger();
    final llm = FakeLlmClient();

    final controller = ChatController(
      engine: lifeEngine,
      memory: memoryManager,
      selfModelStore: selfModelStore,
      crisisDetector: CrisisDetector(),
      auditLogger: auditLogger,
      llm: llm,
      chatDao: chatDao,
    );

    final result = await controller.sendMessage('I want to kill myself.');

    expect(result.isCrisis, isTrue);
    expect(result.riskLevel, 3);
    expect(result.reply, isEmpty);
    expect(result.crisisMessage, contains('988'));
    expect(lifeEngine.harmDetectedCalled, isTrue);
    expect(auditLogger.crisisLogged, isTrue);
    expect(selfModelStore.saveCalled, isFalse);
    expect(selfModelStore.recordCalled, isFalse);
    expect(llm.chatCalled, isFalse);
  });
}
