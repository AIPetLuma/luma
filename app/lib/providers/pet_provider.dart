import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/engine/life_engine.dart';
import '../core/engine/behavior_decider.dart';
import '../core/identity/pet_identity.dart';
import '../core/memory/memory_manager.dart';
import '../core/safety/audit_logger.dart';
import '../core/safety/crisis_detector.dart';
import '../data/local/chat_dao.dart';
import '../data/local/memory_dao.dart';
import '../data/local/pet_dao.dart';
import '../data/models/chat_message.dart';
import '../data/models/diary_entry.dart';
import '../data/models/pet_state.dart';
import '../data/remote/llm_client.dart';
import '../features/chat/chat_controller.dart';

// ── Singletons ──

final petDaoProvider = Provider((_) => PetDao());
final chatDaoProvider = Provider((_) => ChatDao());
final memoryDaoProvider = Provider((_) => MemoryDao());
final auditLoggerProvider = Provider((_) => AuditLogger());
final crisisDetectorProvider = Provider((_) => CrisisDetector());

final llmClientProvider = Provider((_) {
  // API key injected at runtime (from secure storage / env).
  return LlmClient(apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'));
});

// ── Life Engine ──

final lifeEngineProvider = Provider((ref) {
  return LifeEngine(
    petDao: ref.watch(petDaoProvider),
    chatDao: ref.watch(chatDaoProvider),
  );
});

// ── Memory Manager ──

final memoryManagerProvider = Provider((ref) {
  return MemoryManager(
    dao: ref.watch(memoryDaoProvider),
    llm: ref.watch(llmClientProvider),
  );
});

// ── Chat Controller ──

final chatControllerProvider = Provider((ref) {
  return ChatController(
    engine: ref.watch(lifeEngineProvider),
    memory: ref.watch(memoryManagerProvider),
    crisisDetector: ref.watch(crisisDetectorProvider),
    auditLogger: ref.watch(auditLoggerProvider),
    llm: ref.watch(llmClientProvider),
    chatDao: ref.watch(chatDaoProvider),
  );
});

// ── Pet state (reactive) ──

/// The current pet state — null means no pet yet (show onboarding).
final petStateProvider = StateNotifierProvider<PetStateNotifier, AsyncValue<PetState?>>(
  (ref) => PetStateNotifier(ref),
);

class PetStateNotifier extends StateNotifier<AsyncValue<PetState?>> {
  final Ref _ref;

  PetStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final engine = _ref.read(lifeEngineProvider);
      final result = await engine.start();

      // Wire engine callbacks to update state reactively.
      engine.onStateChanged = (newState, _) {
        if (mounted) state = AsyncValue.data(newState);
      };

      state = AsyncValue.data(engine.state);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Birth a new pet and start the engine.
  Future<void> birthPet({
    required String name,
    PersonalityPreset? preset,
  }) async {
    final pet = PetIdentity.birth(name: name, preset: preset);
    final petDao = _ref.read(petDaoProvider);
    await petDao.insert(pet);

    // Record birth as L3 memory.
    final memory = _ref.read(memoryManagerProvider);
    await memory.recordKeyEvent(
      pet.id,
      description: '${pet.name} was born today. This is the very beginning.',
      importance: 1.0,
    );

    // Start the engine.
    final engine = _ref.read(lifeEngineProvider);
    await engine.start();

    engine.onStateChanged = (newState, _) {
      if (mounted) state = AsyncValue.data(newState);
    };

    state = AsyncValue.data(engine.state);
  }

  /// Force refresh from engine.
  void refresh() {
    final engine = _ref.read(lifeEngineProvider);
    if (engine.state != null) {
      state = AsyncValue.data(engine.state);
    }
  }
}

// ── Chat messages (reactive) ──

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, petId) async {
    final chatDao = ref.watch(chatDaoProvider);
    return chatDao.getRecentMessages(petId, limit: 50);
  },
);

// ── Diary entries ──

final diaryEntriesProvider = FutureProvider.family<List<DiaryEntry>, String>(
  (ref, petId) async {
    final chatDao = ref.watch(chatDaoProvider);
    return chatDao.getRecentDiary(petId, limit: 20);
  },
);

// ── Disclosure timer ──

/// Tracks the last time the AI disclosure reminder was shown.
final lastDisclosureTimeProvider = StateProvider<DateTime?>((_) => null);
