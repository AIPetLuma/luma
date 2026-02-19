import 'dart:convert';
import 'emotion.dart';
import 'need.dart';

/// Complete snapshot of a Luma pet's state.
///
/// This is the single source of truth persisted to SQLite and used
/// to inject context into every LLM call.
class PetState {
  final String id;
  String name;
  final DateTime birthday;
  Map<String, double> personality; // Five-factor: openness, conscientiousness,
  //   extraversion, agreeableness, neuroticism
  Needs needs;
  Emotion emotion;
  double trustScore;
  DateTime lastActiveAt;
  int totalInteractions;
  final DateTime createdAt;
  DateTime updatedAt;

  PetState({
    required this.id,
    required this.name,
    required this.birthday,
    required this.personality,
    required this.needs,
    required this.emotion,
    this.trustScore = 0.5,
    required this.lastActiveAt,
    this.totalInteractions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Age in days since birth.
  int get ageDays => DateTime.now().difference(birthday).inDays;

  /// Minutes since last active.
  int get minutesSinceLastActive =>
      DateTime.now().difference(lastActiveAt).inMinutes;

  /// Personality description for prompt injection.
  String get personalityPrompt {
    final o = personality['openness'] ?? 0.5;
    final e = personality['extraversion'] ?? 0.5;
    final a = personality['agreeableness'] ?? 0.5;
    final n = personality['neuroticism'] ?? 0.5;

    final traits = <String>[];
    if (o > 0.6) traits.add('curious and imaginative');
    if (o < 0.4) traits.add('practical and routine-loving');
    if (e > 0.6) traits.add('outgoing and talkative');
    if (e < 0.4) traits.add('quiet and reserved');
    if (a > 0.6) traits.add('gentle and caring');
    if (a < 0.4) traits.add('independent and stubborn');
    if (n > 0.6) traits.add('sensitive and easily startled');
    if (n < 0.4) traits.add('calm and hard to shake');

    if (traits.isEmpty) traits.add('balanced and adaptable');
    return 'Your personality: ${traits.join(', ')}.';
  }

  // ── SQLite serialisation ──

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'birthday': birthday.toIso8601String(),
        'personality': jsonEncode(personality),
        'need_loneliness': needs.loneliness,
        'need_curiosity': needs.curiosity,
        'need_fatigue': needs.fatigue,
        'need_security': needs.security,
        'emotion_valence': emotion.valence,
        'emotion_arousal': emotion.arousal,
        'trust_score': trustScore,
        'last_active_at': lastActiveAt.toIso8601String(),
        'total_interactions': totalInteractions,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PetState.fromMap(Map<String, dynamic> m) => PetState(
        id: m['id'] as String,
        name: m['name'] as String,
        birthday: DateTime.parse(m['birthday'] as String),
        personality: Map<String, double>.from(
          jsonDecode(m['personality'] as String) as Map,
        ),
        needs: Needs(
          loneliness: (m['need_loneliness'] as num).toDouble(),
          curiosity: (m['need_curiosity'] as num).toDouble(),
          fatigue: (m['need_fatigue'] as num).toDouble(),
          security: (m['need_security'] as num).toDouble(),
        ),
        emotion: Emotion(
          valence: (m['emotion_valence'] as num).toDouble(),
          arousal: (m['emotion_arousal'] as num).toDouble(),
        ),
        trustScore: (m['trust_score'] as num).toDouble(),
        lastActiveAt: DateTime.parse(m['last_active_at'] as String),
        totalInteractions: (m['total_interactions'] as num).toInt(),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
