import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/reflection_engine.dart';
import 'package:luma/core/engine/goal_system.dart';
import 'package:luma/core/engine/internal_monologue.dart';
import 'package:luma/core/identity/self_model.dart';
import 'package:luma/core/memory/self_model_store.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/memory_entry.dart';
import 'package:luma/data/local/memory_dao.dart';

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
    final matches = _entries
        .where(
          (e) =>
              e.petId == petId &&
              e.level == MemoryLevel.longTerm &&
              e.content.startsWith(prefix),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.take(limit).toList();
  }
}

PetState _petState() {
  final now = DateTime(2026, 3, 10, 12, 0, 0);
  return PetState(
    id: 'pet-self-1',
    name: 'Sisi',
    birthday: now.subtract(const Duration(days: 3)),
    personality: {
      'openness': 0.7,
      'extraversion': 0.6,
      'agreeableness': 0.5,
      'neuroticism': 0.4,
    },
    needs: Needs(
      loneliness: 0.85,
      curiosity: 0.2,
      fatigue: 0.1,
      security: 0.6,
    ),
    emotion: Emotion(valence: 0.1, arousal: 0.2),
    lastActiveAt: now,
    createdAt: now.subtract(const Duration(days: 3)),
    updatedAt: now,
  );
}

void main() {
  test('SelfModel JSON roundtrip and prompt fragment', () {
    final model = SelfModel(
      values: {'connection': 0.8, 'curiosity': 0.2},
      traits: {'extraversion': 0.7},
      beliefs: const ['Connection matters most.'],
      confidence: 0.7,
      updatedAt: DateTime(2026, 3, 10),
    );

    final restored = SelfModel.fromJsonString(model.toJsonString());
    expect(restored.values['connection'], closeTo(0.8, 0.001));
    expect(restored.beliefs.first, contains('Connection'));
    expect(restored.toPromptFragment(), contains('primary values'));
  });

  test('ReflectionEngine prioritizes social goal in self model', () {
    final engine = ReflectionEngine();
    final state = _petState();
    final goals = [
      const Goal(
        type: GoalType.social,
        description: 'Tell owner about my day',
        progress: 0.0,
        priority: 0.9,
      ),
    ];
    const thought = Thought(
      content: 'I really want to share my day.',
      trigger: ThoughtTrigger.goal,
      emotionalWeight: 0.6,
      shareability: 0.5,
    );

    final previous = SelfModel(
      values: {'connection': 0.4, 'curiosity': 0.2, 'rest': 0.1, 'safety': 0.3},
      traits: {'extraversion': 0.6},
      beliefs: const [],
      confidence: 0.5,
      updatedAt: DateTime(2026, 3, 9),
    );

    final result = engine.reflect(
      state: state,
      goals: goals,
      thought: thought,
      trigger: 'chat',
      previous: previous,
    );

    expect(result.model.values['connection']!, greaterThan(0.4));
    expect(result.record.summary, contains('chat'));
  });

  test('SelfModelStore save/load returns latest model', () async {
    final dao = FakeMemoryDao();
    final store = SelfModelStore(dao: dao);

    final model = SelfModel(
      values: {'connection': 0.7, 'curiosity': 0.3, 'rest': 0.2, 'safety': 0.4},
      traits: {'openness': 0.5},
      beliefs: const ['I value connection.'],
      confidence: 0.6,
      updatedAt: DateTime(2026, 3, 10, 12, 0, 0),
    );

    await store.save('pet-self-1', model);
    final loaded = await store.load('pet-self-1');
    expect(loaded, isNotNull);
    expect(loaded!.values['connection'], closeTo(0.7, 0.001));
  });
}
