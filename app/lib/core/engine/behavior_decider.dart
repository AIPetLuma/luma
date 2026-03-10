
import 'dart:math';

import '../../data/models/pet_state.dart';

/// Translates the pet's internal state into concrete behaviour decisions.
///
/// V2 enhancements:
/// - Probabilistic decisions (sigmoid-based probability instead of hard thresholds)
/// - Personality modulates action probability
/// - Safety-critical actions (withdraw, sleep) remain deterministic
class BehaviorDecider {
  final Random _rng;

  BehaviorDecider({Random? random}) : _rng = random ?? Random();

  /// Evaluate what actions the pet should take right now.
  BehaviorDecision evaluate(PetState state) {
    final actions = <PetAction>[];
    final extraversion = state.personality['extraversion'] ?? 0.5;

    // ── Deterministic: withdraw (safety-critical welfare mechanism) ──
    if (state.emotion.mayRefuseResponse || state.needs.security < 0.2) {
      actions.add(PetAction.withdraw);
    }

    // ── Deterministic: sleep at extreme fatigue ──
    if (state.needs.fatigue >= 0.9) {
      actions.add(PetAction.sleep);
    }

    // ── Probabilistic: reach out ──
    if (!actions.contains(PetAction.withdraw) &&
        !actions.contains(PetAction.sleep)) {
      final reachOutProb = _sigmoid(
            (state.needs.loneliness - 0.6) * 6,
          ) *
          (0.7 + extraversion * 0.6); // Extraverts reach out more
      if (_rng.nextDouble() < reachOutProb) {
        actions.add(PetAction.reachOut);
      }

      // ── Probabilistic: write diary ──
      if (state.needs.curiosity > 0.5 && state.emotion.arousal > 0.3) {
        final diaryProb = _sigmoid(
          (state.needs.curiosity - 0.5) * 4 +
              (state.emotion.arousal - 0.3) * 3,
        ) * 0.7;
        if (_rng.nextDouble() < diaryProb) {
          actions.add(PetAction.writeDiary);
        }
      }
    }

    return BehaviorDecision(
      actions: actions,
      conversationStyle: _resolveStyle(state),
      shouldInitiateContact: actions.contains(PetAction.reachOut),
    );
  }

  ConversationStyle _resolveStyle(PetState state) {
    final emotion = state.emotion;
    final needs = state.needs;

    if (emotion.mayRefuseResponse) {
      return ConversationStyle.withdrawn;
    }
    if (needs.fatigue >= 0.8) {
      return ConversationStyle.sleepy;
    }
    if (emotion.valence < -0.3) {
      return ConversationStyle.melancholy;
    }
    if (needs.curiosity > 0.6 && emotion.arousal > 0.4) {
      return ConversationStyle.curious;
    }
    if (emotion.valence > 0.3) {
      return ConversationStyle.happy;
    }

    return ConversationStyle.neutral;
  }

  /// Sigmoid function for smooth probability transition.
  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));
}

class BehaviorDecision {
  final List<PetAction> actions;
  final ConversationStyle conversationStyle;
  final bool shouldInitiateContact;

  const BehaviorDecision({
    required this.actions,
    required this.conversationStyle,
    required this.shouldInitiateContact,
  });
}

enum PetAction {
  reachOut,   // send push notification
  writeDiary, // generate diary entry
  sleep,      // enter low-responsiveness mode
  withdraw,   // welfare: refuse to respond
}

enum ConversationStyle {
  happy,
  curious,
  neutral,
  melancholy,
  sleepy,
  withdrawn,
}
