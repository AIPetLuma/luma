import 'dart:math';
import '../../data/models/pet_state.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/need.dart';
import '../../data/models/emotion.dart';
import '../../shared/constants.dart';
import 'need_system.dart';
import 'emotion_system.dart';
import 'behavior_decider.dart';

/// Simulates the passage of time while the user was away.
///
/// When the app returns to foreground, this module fast-forwards
/// through the elapsed minutes, ticking needs and emotions so the
/// pet has truly "lived through" the time apart. This is the core
/// of the "it runs while you're away" promise.
class TimeSimulator {
  final NeedSystem _needSystem;
  final EmotionSystem _emotionSystem;
  final BehaviorDecider _behaviorDecider;
  final _rng = Random();

  TimeSimulator({
    NeedSystem? needSystem,
    EmotionSystem? emotionSystem,
    BehaviorDecider? behaviorDecider,
  })  : _needSystem = needSystem ?? NeedSystem(),
        _emotionSystem = emotionSystem ?? EmotionSystem(),
        _behaviorDecider = behaviorDecider ?? BehaviorDecider();

  /// Simulate [elapsedMinutes] of offline time, returning the updated
  /// pet state and any diary entries generated.
  SimulationResult simulate(PetState state, int elapsedMinutes) {
    // Cap simulation to avoid excessive computation.
    final cappedMinutes = elapsedMinutes.clamp(
      0,
      LumaConstants.maxOfflineSimulationHours * 60,
    );

    final diaryEntries = <DiaryEntry>[];
    var needs = state.needs.copyWith();
    var emotion = state.emotion.copyWith();

    // Simulate in 30-minute chunks for efficiency with some granularity.
    final chunkSize = 30;
    final chunks = (cappedMinutes / chunkSize).ceil();

    for (var i = 0; i < chunks; i++) {
      final minutesThisChunk =
          (i == chunks - 1) ? cappedMinutes % chunkSize : chunkSize;
      if (minutesThisChunk == 0 && i > 0) continue;

      final mins = minutesThisChunk > 0 ? minutesThisChunk.toDouble() : chunkSize.toDouble();

      needs = _needSystem.tick(needs, mins);
      emotion = _emotionSystem.tick(emotion, needs, mins);

      // Every ~4 hours, maybe generate a diary entry.
      if (i > 0 && i % 8 == 0 && _rng.nextDouble() < 0.6) {
        final chunkTime = state.lastActiveAt.add(
          Duration(minutes: i * chunkSize),
        );
        diaryEntries.add(DiaryEntry(
          petId: state.id,
          content: _generateDiaryHint(emotion, needs, chunkTime),
          mood: emotion.label,
          createdAt: chunkTime,
        ));
      }
    }

    // Build the updated state.
    final updatedState = PetState(
      id: state.id,
      name: state.name,
      birthday: state.birthday,
      personality: state.personality,
      needs: needs,
      emotion: emotion,
      trustScore: state.trustScore,
      lastActiveAt: DateTime.now(),
      totalInteractions: state.totalInteractions,
      createdAt: state.createdAt,
      updatedAt: DateTime.now(),
    );

    return SimulationResult(
      state: updatedState,
      diaryEntries: diaryEntries,
      elapsedMinutes: cappedMinutes,
      reunionMood: _describeReunion(emotion, needs, cappedMinutes),
    );
  }

  /// A short hint for the diary entry (to be expanded by LLM later).
  String _generateDiaryHint(Emotion emotion, Needs needs, DateTime time) {
    final hour = time.hour;
    final timeOfDay =
        hour < 6 ? 'late night' :
        hour < 12 ? 'morning' :
        hour < 18 ? 'afternoon' : 'evening';

    final fragments = <String>[
      if (needs.loneliness > 0.7)
        'Felt a bit lonely this $timeOfDay.',
      if (needs.curiosity > 0.7)
        'Got curious about something this $timeOfDay.',
      if (needs.fatigue > 0.8)
        'Was feeling sleepy this $timeOfDay.',
      if (emotion.valence > 0.3)
        'Had a peaceful $timeOfDay.',
      if (emotion.valence < -0.3)
        'This $timeOfDay felt a little heavy.',
    ];

    if (fragments.isEmpty) {
      fragments.add('Spent a quiet $timeOfDay.');
    }

    return fragments.join(' ');
  }

  /// Describe how the pet feels upon reunion.
  ReunionMood _describeReunion(
    Emotion emotion,
    Needs needs,
    int minutesApart,
  ) {
    if (minutesApart < 30) {
      return ReunionMood.brief;
    }
    if (needs.loneliness > 0.8) {
      return emotion.valence > 0 ? ReunionMood.excitedReunion : ReunionMood.needyReunion;
    }
    if (minutesApart > 60 * 24) {
      return ReunionMood.longApart;
    }
    return ReunionMood.normalReturn;
  }
}

class SimulationResult {
  final PetState state;
  final List<DiaryEntry> diaryEntries;
  final int elapsedMinutes;
  final ReunionMood reunionMood;

  const SimulationResult({
    required this.state,
    required this.diaryEntries,
    required this.elapsedMinutes,
    required this.reunionMood,
  });
}

enum ReunionMood {
  brief,          // gone < 30 min — no special reaction
  normalReturn,   // gone a few hours — gentle greeting
  excitedReunion, // lonely but happy — "I missed you!"
  needyReunion,   // lonely and sad — clingy, needs reassurance
  longApart,      // gone > 24 hours — significant reaction
}
