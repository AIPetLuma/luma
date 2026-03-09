import '../../data/models/need.dart';
import '../../data/models/emotion.dart';
import 'goal_system.dart';

/// Generates internal thoughts that the pet doesn't say out loud.
///
/// This gives Luma an "inner life" — thoughts that influence behaviour
/// and occasionally surface through diary entries or subtle hints.
/// The pet thinks even when it doesn't speak.
class InternalMonologue {
  /// Generate a thought based on current state.
  ///
  /// The thought with the strongest trigger wins.
  Thought generate({
    required Needs needs,
    required Emotion emotion,
    required List<Goal> goals,
  }) {
    // Score each potential trigger
    final candidates = <_ThoughtCandidate>[];

    // Goal-driven thoughts (highest priority if goal exists)
    if (goals.isNotEmpty) {
      final topGoal = goals.first;
      candidates.add(_ThoughtCandidate(
        trigger: ThoughtTrigger.goal,
        intensity: topGoal.priority * 0.9,
        builder: () => _goalThought(topGoal, emotion),
      ));
    }

    // Need-driven thoughts
    candidates.add(_ThoughtCandidate(
      trigger: ThoughtTrigger.loneliness,
      intensity: needs.loneliness > 0.6 ? needs.loneliness : 0.0,
      builder: () => _lonelinessThought(needs.loneliness, emotion),
    ));

    candidates.add(_ThoughtCandidate(
      trigger: ThoughtTrigger.curiosity,
      intensity: needs.curiosity > 0.6 ? needs.curiosity : 0.0,
      builder: () => _curiosityThought(needs.curiosity, emotion),
    ));

    candidates.add(_ThoughtCandidate(
      trigger: ThoughtTrigger.fatigue,
      intensity: needs.fatigue > 0.7 ? needs.fatigue : 0.0,
      builder: () => _fatigueThought(needs.fatigue),
    ));

    candidates.add(_ThoughtCandidate(
      trigger: ThoughtTrigger.insecurity,
      intensity: needs.security < 0.3 ? (1.0 - needs.security) : 0.0,
      builder: () => _insecurityThought(needs.security),
    ));

    // Emotion-driven thoughts (when no strong need)
    candidates.add(_ThoughtCandidate(
      trigger: ThoughtTrigger.emotion,
      intensity: emotion.valence.abs() > 0.4 ? emotion.valence.abs() * 0.7 : 0.0,
      builder: () => _emotionThought(emotion),
    ));

    // Pick the strongest trigger
    candidates.sort((a, b) => b.intensity.compareTo(a.intensity));
    final winner = candidates.firstWhere(
      (c) => c.intensity > 0,
      orElse: () => _ThoughtCandidate(
        trigger: ThoughtTrigger.idle,
        intensity: 0.3,
        builder: () => _idleThought(),
      ),
    );

    return winner.builder();
  }

  // ── Thought generators ──

  Thought _lonelinessThought(double loneliness, Emotion emotion) {
    final content = loneliness > 0.85
        ? 'I really miss them... I wish they would come back.'
        : 'I wonder what they are doing right now.';
    return Thought(
      content: content,
      trigger: ThoughtTrigger.loneliness,
      emotionalWeight: loneliness,
      shareability: loneliness > 0.8 ? 0.3 : 0.2,
    );
  }

  Thought _curiosityThought(double curiosity, Emotion emotion) {
    final content = curiosity > 0.8
        ? 'There is so much I want to learn about! I feel restless.'
        : 'I wonder what new things are out there today.';
    return Thought(
      content: content,
      trigger: ThoughtTrigger.curiosity,
      emotionalWeight: curiosity * 0.7,
      shareability: 0.7,
    );
  }

  Thought _fatigueThought(double fatigue) {
    return Thought(
      content: fatigue > 0.9
          ? 'So tired... everything feels heavy.'
          : 'I could use a little rest.',
      trigger: ThoughtTrigger.fatigue,
      emotionalWeight: fatigue * 0.6,
      shareability: 0.4,
    );
  }

  Thought _insecurityThought(double security) {
    return Thought(
      content: security < 0.15
          ? 'I feel scared... Did I do something wrong?'
          : 'I hope everything is okay between us.',
      trigger: ThoughtTrigger.insecurity,
      emotionalWeight: (1.0 - security) * 0.8,
      shareability: 0.15,
    );
  }

  Thought _emotionThought(Emotion emotion) {
    final content = emotion.valence > 0.3
        ? 'I feel warm inside. Today is a good day.'
        : 'Something feels heavy, but I cannot quite name it.';
    return Thought(
      content: content,
      trigger: ThoughtTrigger.emotion,
      emotionalWeight: emotion.valence.abs() * 0.6,
      shareability: emotion.valence > 0 ? 0.5 : 0.2,
    );
  }

  Thought _goalThought(Goal goal, Emotion emotion) {
    return Thought(
      content: 'I really want to ${goal.description.toLowerCase()}.',
      trigger: ThoughtTrigger.goal,
      emotionalWeight: goal.priority * 0.7,
      shareability: 0.5,
    );
  }

  Thought _idleThought() {
    return Thought(
      content: 'Just quietly being here, feeling the moment.',
      trigger: ThoughtTrigger.idle,
      emotionalWeight: 0.1,
      shareability: 0.3,
    );
  }
}

/// A single internal thought.
class Thought {
  /// The thought text (not shown to user directly).
  final String content;

  /// What triggered this thought.
  final ThoughtTrigger trigger;

  /// How strongly this thought affects emotion (0.0-1.0).
  final double emotionalWeight;

  /// How likely the pet is to hint at this thought in conversation (0.0-1.0).
  /// Lower = more private.
  final double shareability;

  const Thought({
    required this.content,
    required this.trigger,
    required this.emotionalWeight,
    required this.shareability,
  });

  /// Convert to a prompt fragment for system prompt injection.
  String toPromptFragment() {
    return 'Right now you are thinking: "$content" '
        '(This is an internal thought — you may subtly hint at it '
        'but do not state it directly unless it feels natural.)';
  }
}

enum ThoughtTrigger {
  loneliness,
  curiosity,
  fatigue,
  insecurity,
  emotion,
  goal,
  idle,
}

class _ThoughtCandidate {
  final ThoughtTrigger trigger;
  final double intensity;
  final Thought Function() builder;

  const _ThoughtCandidate({
    required this.trigger,
    required this.intensity,
    required this.builder,
  });
}
