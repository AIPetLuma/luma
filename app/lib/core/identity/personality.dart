import 'dart:math';

/// Manages gradual personality evolution over time.
///
/// Personality traits shift slowly based on interaction patterns —
/// a pet that receives lots of curious questions becomes more curious;
/// one that's treated gently becomes gentler. After months, the pet's
/// personality is visibly shaped by the relationship.
class PersonalityEvolver {
  static const _evolutionRate = 0.002; // per interaction, very slow
  static const _maxShift = 0.15; // max shift from initial value per month

  /// Nudge personality based on an interaction pattern.
  ///
  /// Returns an updated personality map.
  Map<String, double> evolve(
    Map<String, double> current,
    PersonalitySignal signal,
  ) {
    final updated = Map<String, double>.from(current);

    switch (signal) {
      case PersonalitySignal.curiousInteraction:
        _nudge(updated, 'openness', _evolutionRate);
        break;
      case PersonalitySignal.gentleInteraction:
        _nudge(updated, 'agreeableness', _evolutionRate);
        _nudge(updated, 'neuroticism', -_evolutionRate * 0.5);
        break;
      case PersonalitySignal.playfulInteraction:
        _nudge(updated, 'extraversion', _evolutionRate);
        break;
      case PersonalitySignal.harshInteraction:
        _nudge(updated, 'neuroticism', _evolutionRate * 2);
        _nudge(updated, 'extraversion', -_evolutionRate);
        break;
      case PersonalitySignal.longConversation:
        _nudge(updated, 'extraversion', _evolutionRate * 0.5);
        _nudge(updated, 'openness', _evolutionRate * 0.5);
        break;
      case PersonalitySignal.neglect:
        _nudge(updated, 'neuroticism', _evolutionRate);
        _nudge(updated, 'extraversion', -_evolutionRate * 0.5);
        break;
    }

    return updated;
  }

  void _nudge(Map<String, double> traits, String key, double amount) {
    final current = traits[key] ?? 0.5;
    traits[key] = (current + amount).clamp(0.05, 0.95);
  }
}

enum PersonalitySignal {
  curiousInteraction,
  gentleInteraction,
  playfulInteraction,
  harshInteraction,
  longConversation,
  neglect,
}
