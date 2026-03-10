import '../../data/models/need.dart';
import '../../data/models/emotion.dart';

/// Manages short-term goals that give Luma intentional behaviour.
///
/// Goals are generated from needs + personality + emotion,
/// creating the sense that the pet "wants to do something"
/// rather than just passively reacting.
class GoalSystem {
  static const _maxActiveGoals = 3;

  /// Generate goals based on current state.
  ///
  /// Returns up to [_maxActiveGoals] goals, one per type at most.
  List<Goal> generateGoals({
    required Needs needs,
    required Emotion emotion,
    required Map<String, double> personality,
  }) {
    final candidates = <Goal>[];

    // Exhausted pet only generates rest/comfort goals
    if (needs.fatigue >= 0.85) {
      candidates.add(Goal(
        type: GoalType.rest,
        description: 'Find a quiet moment to rest',
        progress: 0.0,
        priority: 0.9,
      ));
      if (needs.security < 0.4) {
        candidates.add(Goal(
          type: GoalType.comfort,
          description: 'Seek reassurance from owner',
          progress: 0.0,
          priority: 0.7,
        ));
      }
      return _limitAndSort(candidates);
    }

    // Social goal: driven by loneliness
    if (needs.loneliness > 0.6) {
      final extraversion = personality['extraversion'] ?? 0.5;
      candidates.add(Goal(
        type: GoalType.social,
        description: extraversion > 0.5
            ? 'Tell owner about my day'
            : 'Spend quiet time with owner',
        progress: 0.0,
        priority: _normalize(needs.loneliness, 0.6, 1.0),
      ));
    }

    // Exploration goal: driven by curiosity + openness
    if (needs.curiosity > 0.6) {
      final openness = personality['openness'] ?? 0.5;
      if (openness > 0.3) {
        candidates.add(Goal(
          type: GoalType.exploration,
          description: openness > 0.6
              ? 'Learn something new today'
              : 'Think about something interesting',
          progress: 0.0,
          priority: _normalize(needs.curiosity, 0.6, 1.0) * (0.5 + openness * 0.5),
        ));
      }
    }

    // Comfort goal: driven by low security
    if (needs.security < 0.4) {
      candidates.add(Goal(
        type: GoalType.comfort,
        description: 'Feel safe and cared for',
        progress: 0.0,
        priority: _normalize(1.0 - needs.security, 0.6, 1.0),
      ));
    }

    // Rest goal: moderate fatigue
    if (needs.fatigue > 0.6) {
      candidates.add(Goal(
        type: GoalType.rest,
        description: 'Take a little break',
        progress: 0.0,
        priority: _normalize(needs.fatigue, 0.6, 1.0) * 0.7,
      ));
    }

    return _limitAndSort(candidates);
  }

  /// Advance a goal based on an event.
  Goal advanceGoal(Goal goal, GoalEvent event) {
    var delta = 0.0;

    switch (goal.type) {
      case GoalType.social:
        if (event == GoalEvent.chatReceived) delta = 0.3;
        if (event == GoalEvent.positiveInteraction) delta = 0.4;
        break;
      case GoalType.exploration:
        if (event == GoalEvent.newTopicDiscussed) delta = 0.4;
        if (event == GoalEvent.chatReceived) delta = 0.15;
        break;
      case GoalType.comfort:
        if (event == GoalEvent.positiveInteraction) delta = 0.35;
        if (event == GoalEvent.chatReceived) delta = 0.2;
        break;
      case GoalType.rest:
        if (event == GoalEvent.timePassed) delta = 0.2;
        if (event == GoalEvent.sleepTriggered) delta = 0.5;
        break;
    }

    final newProgress = (goal.progress + delta).clamp(0.0, 1.0);
    return Goal(
      type: goal.type,
      description: goal.description,
      progress: newProgress,
      priority: goal.priority,
    );
  }

  /// Emotion delta when a goal is completed.
  EmotionDelta emotionDeltaForCompletion(Goal goal) {
    return EmotionDelta(
      valence: 0.1 + goal.priority * 0.15,
      arousal: 0.05,
    );
  }

  /// Emotion delta when a goal fails (timed out or overridden).
  EmotionDelta emotionDeltaForFailure(Goal goal) {
    return EmotionDelta(
      valence: -(0.05 + goal.priority * 0.1),
      arousal: 0.05,
    );
  }

  List<Goal> _limitAndSort(List<Goal> candidates) {
    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    // Deduplicate by type
    final seen = <GoalType>{};
    final result = <Goal>[];
    for (final g in candidates) {
      if (!seen.contains(g.type)) {
        seen.add(g.type);
        result.add(g);
      }
      if (result.length >= _maxActiveGoals) break;
    }
    return result;
  }

  double _normalize(double value, double min, double max) {
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}

class Goal {
  final GoalType type;
  final String description;
  final double progress; // 0.0 to 1.0
  final double priority; // 0.0 to 1.0

  const Goal({
    required this.type,
    required this.description,
    required this.progress,
    required this.priority,
  });

  bool get isComplete => progress >= 1.0;
}

enum GoalType {
  social,      // wants to interact with owner
  exploration, // wants to learn or discover
  comfort,     // wants to feel safe
  rest,        // wants to recharge
}

enum GoalEvent {
  chatReceived,
  positiveInteraction,
  newTopicDiscussed,
  timePassed,
  sleepTriggered,
}

class EmotionDelta {
  final double valence;
  final double arousal;
  const EmotionDelta({required this.valence, required this.arousal});
}
