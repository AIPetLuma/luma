import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../data/models/pet_state.dart';
import '../../data/models/need.dart';
import '../../data/models/emotion.dart';

/// Factory for creating a new Luma pet with a unique identity.
///
/// Each pet is a globally unique instance — this uniqueness is
/// architectural, not marketing. The ID is generated once and
/// bound to local storage; it cannot be duplicated or migrated
/// without the original device.
class PetIdentity {
  static const _uuid = Uuid();
  static final _rng = Random();

  /// Create a brand new pet with generated personality.
  static PetState birth({
    required String name,
    PersonalityPreset? preset,
  }) {
    final now = DateTime.now();
    return PetState(
      id: _uuid.v4(),
      name: name,
      birthday: now,
      personality: _generatePersonality(preset),
      needs: Needs(),
      emotion: Emotion(valence: 0.4, arousal: 0.5), // slightly happy at birth
      trustScore: 0.5,
      lastActiveAt: now,
      totalInteractions: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generate five-factor personality values.
  static Map<String, double> _generatePersonality(PersonalityPreset? preset) {
    if (preset != null) return preset.values;

    // Random personality with some variance.
    return {
      'openness': _randTrait(),
      'conscientiousness': _randTrait(),
      'extraversion': _randTrait(),
      'agreeableness': _randTrait(),
      'neuroticism': _randTrait(),
    };
  }

  static double _randTrait() => 0.3 + _rng.nextDouble() * 0.4; // 0.3–0.7
}

/// Pre-built personality templates for user selection during onboarding.
enum PersonalityPreset {
  curious(
    label: 'Explorer',
    description: 'Curious, adventurous, always asking questions',
    values: {
      'openness': 0.8,
      'conscientiousness': 0.4,
      'extraversion': 0.6,
      'agreeableness': 0.5,
      'neuroticism': 0.3,
    },
  ),
  gentle(
    label: 'Gentle Soul',
    description: 'Calm, caring, sensitive to your mood',
    values: {
      'openness': 0.5,
      'conscientiousness': 0.6,
      'extraversion': 0.3,
      'agreeableness': 0.8,
      'neuroticism': 0.5,
    },
  ),
  playful(
    label: 'Playful Spirit',
    description: 'Energetic, mischievous, loves surprises',
    values: {
      'openness': 0.7,
      'conscientiousness': 0.3,
      'extraversion': 0.8,
      'agreeableness': 0.6,
      'neuroticism': 0.2,
    },
  ),
  shy(
    label: 'Shy Dreamer',
    description: 'Quiet, imaginative, warms up slowly',
    values: {
      'openness': 0.6,
      'conscientiousness': 0.5,
      'extraversion': 0.2,
      'agreeableness': 0.7,
      'neuroticism': 0.6,
    },
  );

  final String label;
  final String description;
  final Map<String, double> values;

  const PersonalityPreset({
    required this.label,
    required this.description,
    required this.values,
  });
}
