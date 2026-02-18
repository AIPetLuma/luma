import 'dart:math';

/// The four fundamental needs that drive Luma's internal state.
///
/// Each need drifts over time and is satisfied by specific interactions.
/// Values are clamped to [0.0, 1.0].
class Needs {
  double loneliness;
  double curiosity;
  double fatigue;
  double security;

  Needs({
    this.loneliness = 0.5,
    this.curiosity = 0.5,
    this.fatigue = 0.0,
    this.security = 0.5,
  });

  /// Clamp all values to valid range.
  void clamp() {
    loneliness = loneliness.clamp(0.0, 1.0);
    curiosity = curiosity.clamp(0.0, 1.0);
    fatigue = fatigue.clamp(0.0, 1.0);
    security = security.clamp(0.0, 1.0);
  }

  Map<String, double> toMap() => {
        'loneliness': loneliness,
        'curiosity': curiosity,
        'fatigue': fatigue,
        'security': security,
      };

  factory Needs.fromMap(Map<String, dynamic> m) => Needs(
        loneliness: (m['loneliness'] as num?)?.toDouble() ?? 0.5,
        curiosity: (m['curiosity'] as num?)?.toDouble() ?? 0.5,
        fatigue: (m['fatigue'] as num?)?.toDouble() ?? 0.0,
        security: (m['security'] as num?)?.toDouble() ?? 0.5,
      );

  Needs copyWith({
    double? loneliness,
    double? curiosity,
    double? fatigue,
    double? security,
  }) =>
      Needs(
        loneliness: loneliness ?? this.loneliness,
        curiosity: curiosity ?? this.curiosity,
        fatigue: fatigue ?? this.fatigue,
        security: security ?? this.security,
      );

  @override
  String toString() =>
      'Needs(lonely=${loneliness.toStringAsFixed(2)}, '
      'curious=${curiosity.toStringAsFixed(2)}, '
      'tired=${fatigue.toStringAsFixed(2)}, '
      'safe=${security.toStringAsFixed(2)})';
}
