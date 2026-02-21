import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/engine/life_engine.dart';
import '../core/identity/pet_identity.dart';
import '../core/memory/memory_manager.dart';
import '../core/safety/audit_logger.dart';
import '../core/safety/crisis_detector.dart';
import '../core/services/notification_service.dart';
import '../data/local/chat_dao.dart';
import '../data/local/memory_dao.dart';
import '../data/local/pet_dao.dart';
import '../data/local/secure_storage.dart';
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

/// API key loaded from secure storage. Falls back to compile-time env var.
final apiKeyProvider = FutureProvider<String>((ref) async {
  final stored = await SecureStorage.getApiKey();
  if (stored != null && stored.isNotEmpty) return stored;

  const generic = String.fromEnvironment('LLM_API_KEY');
  if (generic.isNotEmpty) return generic;

  const anthropic = String.fromEnvironment('ANTHROPIC_API_KEY');
  if (anthropic.isNotEmpty) return anthropic;

  return const String.fromEnvironment('OPENAI_API_KEY');
});

final llmClientProvider = Provider((ref) {
  final apiKeyAsync = ref.watch(apiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull ?? '';
  const rawProvider = String.fromEnvironment('LLM_PROVIDER', defaultValue: 'auto');
  const baseUrl = String.fromEnvironment('LLM_BASE_URL');
  const model = String.fromEnvironment('LLM_MODEL');

  final provider = LlmClient.resolveProvider(
    raw: rawProvider,
    apiKey: apiKey,
    baseUrl: baseUrl,
  );

  return LlmClient(
    apiKey: apiKey,
    provider: provider,
    baseUrl: baseUrl.isEmpty ? null : baseUrl,
    defaultModel: model.isEmpty ? null : model,
  );
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
      await engine.start();

      // Wire engine callbacks to update state reactively.
      engine.onStateChanged = (newState, _) {
        if (mounted) state = AsyncValue.data(newState);
      };

      // Wire push notifications when pet reaches out.
      engine.onReachOut = (petState) {
        NotificationService.showPetMessage(
          title: petState.name,
          body: _reachOutMessage(petState),
        );
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

    engine.onReachOut = (petState) {
      NotificationService.showPetMessage(
        title: petState.name,
        body: _reachOutMessage(petState),
      );
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

  String _reachOutMessage(PetState pet) {
    final mood = pet.emotion.label;
    return switch (mood) {
      'melancholy' => '${pet.name} is feeling a bit down and misses you.',
      'anxious' => '${pet.name} seems worried. Maybe check in?',
      'withdrawn' => '${pet.name} has been quiet for a while...',
      'curious' => '${pet.name} found something interesting!',
      _ => '${pet.name} is thinking about you!',
    };
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
