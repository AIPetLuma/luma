import '../../data/models/pet_state.dart';
import '../identity/self_model.dart';
import 'goal_system.dart';
import 'internal_monologue.dart';

/// Updates the self model based on recent state and goals.
class ReflectionEngine {
  ReflectionResult reflect({
    required PetState state,
    required List<Goal> goals,
    required Thought thought,
    required String trigger,
    SelfModel? previous,
  }) {
    final base = previous ?? _initialModel(state);
    final values = Map<String, double>.from(base.values);
    final adjustments = <String>[];

    if (goals.isNotEmpty) {
      final topGoal = goals.first;
      switch (topGoal.type) {
        case GoalType.social:
          values['connection'] = _bump(values['connection'], 0.12);
          adjustments.add('Prioritize connection due to social goal.');
          break;
        case GoalType.exploration:
          values['curiosity'] = _bump(values['curiosity'], 0.12);
          adjustments.add('Prioritize curiosity due to exploration goal.');
          break;
        case GoalType.comfort:
          values['safety'] = _bump(values['safety'], 0.12);
          adjustments.add('Prioritize safety due to comfort goal.');
          break;
        case GoalType.rest:
          values['rest'] = _bump(values['rest'], 0.12);
          adjustments.add('Prioritize rest due to fatigue.');
          break;
      }
    }

    if (state.emotion.valence < -0.3) {
      values['safety'] = _bump(values['safety'], 0.05);
      adjustments.add('Seek safety after low-valence mood.');
    }
    if (state.emotion.valence > 0.3) {
      values['connection'] = _bump(values['connection'], 0.04);
      adjustments.add('Lean toward connection after positive mood.');
    }

    _normalize(values);

    final beliefs = _beliefsFromValues(values);
    final updated = base.copyWith(
      values: values,
      beliefs: beliefs,
      confidence: _confidenceFromState(state),
      updatedAt: DateTime.now(),
    );

    final summary =
        'Reflection after $trigger; thought=${thought.trigger.name}. '
        'Top value=${_topValue(values)}.';

    return ReflectionResult(
      model: updated,
      record: ReflectionRecord(
        trigger: trigger,
        summary: summary,
        adjustments: adjustments,
        contradictions: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  SelfModel _initialModel(PetState state) {
    final values = <String, double>{
      'connection': state.needs.loneliness.clamp(0.0, 1.0),
      'curiosity': state.needs.curiosity.clamp(0.0, 1.0),
      'rest': state.needs.fatigue.clamp(0.0, 1.0),
      'safety': (1.0 - state.needs.security).clamp(0.0, 1.0),
    };
    final traits = Map<String, double>.from(state.personality);
    final beliefs = _beliefsFromValues(values);
    return SelfModel(
      values: values,
      traits: traits,
      beliefs: beliefs,
      confidence: _confidenceFromState(state),
      updatedAt: DateTime.now(),
    );
  }

  double _confidenceFromState(PetState state) {
    final interactionBoost =
        (state.totalInteractions / 40.0).clamp(0.0, 0.4);
    return (0.4 + interactionBoost).clamp(0.4, 0.8);
  }

  double _bump(double? value, double delta) {
    final base = value ?? 0.5;
    return (base + delta).clamp(0.0, 1.0);
  }

  void _normalize(Map<String, double> values) {
    for (final key in values.keys) {
      values[key] = values[key]!.clamp(0.0, 1.0);
    }
  }

  String _topValue(Map<String, double> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.isEmpty ? 'none' : entries.first.key;
  }

  List<String> _beliefsFromValues(Map<String, double> values) {
    final ordered = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ordered.isEmpty) return const [];
    final top = ordered.first.key;
    return [
      switch (top) {
        'connection' => 'I feel most grounded when I can connect.',
        'curiosity' => 'Exploring new ideas helps me feel alive.',
        'rest' => 'Rest keeps me steady and clear.',
        'safety' => 'Feeling safe helps me open up.',
        _ => 'I try to stay balanced and present.',
      },
    ];
  }
}

class ReflectionResult {
  final SelfModel model;
  final ReflectionRecord record;

  const ReflectionResult({required this.model, required this.record});
}

class ReflectionRecord {
  final String trigger;
  final String summary;
  final List<String> adjustments;
  final List<String> contradictions;
  final DateTime createdAt;

  const ReflectionRecord({
    required this.trigger,
    required this.summary,
    required this.adjustments,
    required this.contradictions,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        'summary': summary,
        'adjustments': adjustments,
        'contradictions': contradictions,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReflectionRecord.fromJson(Map<String, dynamic> json) {
    return ReflectionRecord(
      trigger: json['trigger'] as String,
      summary: json['summary'] as String,
      adjustments: List<String>.from(json['adjustments'] as List? ?? const []),
      contradictions:
          List<String>.from(json['contradictions'] as List? ?? const []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
