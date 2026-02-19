import 'dart:math';
import '../../data/models/emotion.dart';
import '../../data/models/need.dart';
import '../../shared/constants.dart';

/// Generates and decays emotions based on needs and events.
///
/// Emotions are NOT labels — they are internal variables that
/// directly affect Luma's behaviour (reply length, speed, tone,
/// willingness to respond). This is the core distinction between
/// "performing" and "being alive".
class EmotionSystem {
  final _rng = Random();

  /// Advance emotion state by [minutes], decaying toward baseline
  /// and adjusting based on current needs.
  Emotion tick(Emotion current, Needs needs, double minutes) {
    final e = current.copyWith();

    // ── Natural decay toward baseline ──
    final decayAmount = LumaConstants.emotionDecayRate * minutes;
    e.valence = _decayToward(
      e.valence,
      LumaConstants.emotionBaselineValence,
      decayAmount,
    );
    e.arousal = _decayToward(
      e.arousal,
      LumaConstants.emotionBaselineArousal,
      decayAmount,
    );

    // ── Need-driven emotion pressure ──
    // High loneliness → lowers valence (sadder).
    if (needs.loneliness > 0.7) {
      e.valence -= (needs.loneliness - 0.7) * 0.01 * minutes;
    }

    // High curiosity → raises arousal (more energetic).
    if (needs.curiosity > 0.6) {
      e.arousal += (needs.curiosity - 0.6) * 0.005 * minutes;
    }

    // High fatigue → lowers arousal (sluggish).
    if (needs.fatigue > 0.7) {
      e.arousal -= (needs.fatigue - 0.7) * 0.01 * minutes;
    }

    // Low security → lowers valence and raises arousal (anxious).
    if (needs.security < 0.3) {
      e.valence -= (0.3 - needs.security) * 0.015 * minutes;
      e.arousal += (0.3 - needs.security) * 0.005 * minutes;
    }

    // Small random fluctuation (feels alive).
    e.valence += (_rng.nextDouble() - 0.5) * 0.002 * minutes;
    e.arousal += (_rng.nextDouble() - 0.5) * 0.002 * minutes;

    e.clamp();
    return e;
  }

  /// Immediate emotion shift from an interaction event.
  Emotion onEvent(Emotion current, EmotionEvent event) {
    final e = current.copyWith();

    switch (event) {
      case EmotionEvent.userReturned:
        // Reunion — happiness spike proportional to how long apart.
        e.valence += 0.3;
        e.arousal += 0.2;
        break;

      case EmotionEvent.positiveChat:
        e.valence += 0.1;
        e.arousal += 0.05;
        break;

      case EmotionEvent.negativeChat:
        e.valence -= 0.2;
        e.arousal += 0.1; // agitated
        break;

      case EmotionEvent.newTopicShared:
        e.valence += 0.05;
        e.arousal += 0.15; // curiosity spike
        break;

      case EmotionEvent.harmDetected:
        // Welfare trigger — significant negative shift.
        e.valence -= 0.4;
        e.arousal -= 0.2; // withdrawal, not agitation
        break;

      case EmotionEvent.longSilence:
        e.valence -= 0.05;
        e.arousal -= 0.1;
        break;
    }

    e.clamp();
    return e;
  }

  /// How many extra milliseconds to delay the reply (fatigue/sadness).
  int replyDelayMs(Emotion emotion, Needs needs) {
    var delay = LumaConstants.replyDelayBaseMs;

    // Tired → slower replies.
    if (needs.fatigue > 0.7) {
      delay += ((needs.fatigue - 0.7) / 0.3 *
              LumaConstants.replyDelayFatigueExtraMs)
          .round();
    }

    // Melancholy → slightly slower.
    if (emotion.valence < -0.3) {
      delay += 1500;
    }

    return delay;
  }

  /// Suggested max_tokens for the LLM call.
  int suggestedMaxTokens(Emotion emotion) {
    if (emotion.valence > 0.3 && emotion.arousal > 0.4) {
      return LumaConstants.happyMaxTokens;
    }
    if (emotion.valence < -0.3) {
      return LumaConstants.sadMaxTokens;
    }
    return LumaConstants.defaultMaxTokens;
  }

  /// Suggested temperature for the LLM call.
  double suggestedTemperature(Map<String, double> personality) {
    final openness = personality['openness'] ?? 0.5;
    return LumaConstants.baseTemperature + openness * 0.2;
  }

  // ── Helpers ──

  double _decayToward(double current, double target, double amount) {
    if ((current - target).abs() < amount) return target;
    return current > target ? current - amount : current + amount;
  }
}

enum EmotionEvent {
  userReturned,
  positiveChat,
  negativeChat,
  newTopicShared,
  harmDetected,
  longSilence,
}
