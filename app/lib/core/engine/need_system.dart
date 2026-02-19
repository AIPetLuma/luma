import 'dart:math';
import '../../data/models/need.dart';
import '../../shared/constants.dart';

/// Manages the four fundamental needs that drive Luma's behaviour.
///
/// Needs drift over time (simulating a living creature) and are
/// satisfied by specific user interactions. This is the foundation
/// of the "it runs while you're away" experience.
class NeedSystem {
  final _rng = Random();

  /// Advance needs by [minutes] of elapsed time.
  ///
  /// [isInteracting] — whether the user is currently in a conversation.
  /// Called every tick (1 min foreground) or in bulk for offline catch-up.
  Needs tick(Needs current, double minutes, {bool isInteracting = false}) {
    final n = current.copyWith();

    // ── Loneliness: grows when alone, stabilises when interacting ──
    if (isInteracting) {
      // During interaction, loneliness slowly decreases.
      n.loneliness -= 0.005 * minutes;
    } else {
      n.loneliness += LumaConstants.lonelinessOfflineDrift * minutes;
    }

    // ── Curiosity: random walk with slight mean-reversion ──
    final curiosityNoise =
        (_rng.nextDouble() - 0.5) * 2 * LumaConstants.curiosityDriftRange;
    final meanReversion = (0.5 - n.curiosity) * 0.002;
    n.curiosity += (curiosityNoise + meanReversion) * minutes;

    // ── Fatigue: grows during interaction, recovers when idle ──
    if (isInteracting) {
      n.fatigue += LumaConstants.fatigueDriftActive * minutes;
    } else {
      n.fatigue -= LumaConstants.fatigueRecoveryIdle * minutes;
    }

    // ── Security: slow natural decay (trust fades without reinforcement) ──
    n.security -= LumaConstants.securityNaturalDecay * minutes;

    n.clamp();
    return n;
  }

  /// Apply the effect of a single user interaction.
  Needs onInteraction(Needs current, {required InteractionType type}) {
    final n = current.copyWith();

    switch (type) {
      case InteractionType.chat:
        n.loneliness += LumaConstants.lonelinessPerInteraction;
        n.fatigue += 0.02; // slight energy cost
        n.security += LumaConstants.securityPerPositive;
        break;

      case InteractionType.newTopic:
        n.loneliness += LumaConstants.lonelinessPerInteraction;
        n.curiosity += LumaConstants.curiosityPerNewTopic;
        n.security += LumaConstants.securityPerPositive;
        break;

      case InteractionType.positiveGesture:
        n.security += LumaConstants.securityPerPositive * 2;
        n.loneliness -= 0.1;
        break;

      case InteractionType.negativeGesture:
        n.security += LumaConstants.securityPerNegative; // decreases
        n.loneliness += 0.1; // feels more alone after negative input
        break;

      case InteractionType.sleep:
        n.fatigue += LumaConstants.fatiguePerSleep;
        break;
    }

    n.clamp();
    return n;
  }

  /// Check if the pet should send a push notification.
  bool shouldReachOut(Needs needs) =>
      needs.loneliness >= LumaConstants.lonelinessPushThreshold;

  /// Check if the pet is too tired to be fully responsive.
  bool isTired(Needs needs) =>
      needs.fatigue >= LumaConstants.fatigueSlowdownThreshold;

  /// Check if trust is critically low (welfare mechanism).
  bool isInsecure(Needs needs) =>
      needs.security <= LumaConstants.securityWithdrawalThreshold;
}

enum InteractionType {
  chat,
  newTopic,
  positiveGesture,
  negativeGesture,
  sleep,
}
