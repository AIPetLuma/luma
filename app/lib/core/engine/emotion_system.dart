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
///
/// V2 enhancements:
/// - Emotional inertia (extreme emotions resist change)
/// - Event fatigue / habituation (repeated events have less impact)
class EmotionSystem {
  final _rng = Random();

  /// Tracks how many times each event type has fired recently.
  final Map<EmotionEvent, int> _eventCounts = {};

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

    // Slowly decay event fatigue over time (1 count per ~30 min).
    if (minutes > 10) {
      _decayEventFatigue(minutes);
    }

    e.clamp();
    return e;
  }

  /// Immediate emotion shift from an interaction event.
  ///
  /// V2: Applies emotional inertia and event fatigue.
  Emotion onEvent(Emotion current, EmotionEvent event) {
    final e = current.copyWith();

    // ── Get raw deltas for this event ──
    final raw = _rawEventDelta(event);

    // ── Event fatigue: repeated events have less impact ──
    _eventCounts[event] = (_eventCounts[event] ?? 0) + 1;
    final count = _eventCounts[event]!;
    final fatigueFactor = _eventFatigueFactor(count);

    // ── Emotional inertia: extreme emotions resist change ──
    final valenceInertia = _inertiaFactor(e.valence, raw.valence);
    final arousalInertia = _inertiaFactor(e.arousal - 0.5, raw.arousal);

    e.valence += raw.valence * fatigueFactor * valenceInertia;
    e.arousal += raw.arousal * fatigueFactor * arousalInertia;

    e.clamp();
    return e;
  }

  /// Reset event fatigue counters (e.g. after a long break).
  void resetEventFatigue() {
    _eventCounts.clear();
  }

  /// Raw event impact values (before inertia and fatigue).
  _EmotionDelta _rawEventDelta(EmotionEvent event) {
    return switch (event) {
      EmotionEvent.userReturned => const _EmotionDelta(0.3, 0.2),
      EmotionEvent.positiveChat => const _EmotionDelta(0.1, 0.05),
      EmotionEvent.negativeChat => const _EmotionDelta(-0.2, 0.1),
      EmotionEvent.newTopicShared => const _EmotionDelta(0.05, 0.15),
      EmotionEvent.harmDetected => const _EmotionDelta(-0.4, -0.2),
      EmotionEvent.longSilence => const _EmotionDelta(-0.05, -0.1),
    };
  }

  /// Inertia factor: extreme emotions resist change.
  ///
  /// Returns a multiplier in (0, 1]. More extreme currentVal means
  /// more resistance to change in the same direction.
  double _inertiaFactor(double currentVal, double deltaVal) {
    // If delta pushes further from center, apply resistance
    if (currentVal.sign == deltaVal.sign && currentVal.abs() > 0.3) {
      // Resistance grows with how extreme the current value is
      return max(0.3, 1.0 - pow(currentVal.abs(), 1.5) * 0.5);
    }
    // If delta pulls back toward center, no extra resistance
    return 1.0;
  }

  /// Event fatigue: the Nth occurrence of the same event has less impact.
  ///
  /// Returns a multiplier in [0.3, 1.0].
  double _eventFatigueFactor(int count) {
    return max(0.3, 1.0 - (count - 1) * 0.12);
  }

  /// Gradually decay event counts over time.
  void _decayEventFatigue(double minutes) {
    final decayAmount = (minutes / 30).floor();
    if (decayAmount <= 0) return;
    for (final key in _eventCounts.keys.toList()) {
      _eventCounts[key] = max(0, _eventCounts[key]! - decayAmount);
      if (_eventCounts[key] == 0) _eventCounts.remove(key);
    }
  }

  /// How many extra milliseconds to delay the reply (fatigue/sadness).
  int replyDelayMs(Emotion emotion, Needs needs) {
    var delay = LumaConstants.replyDelayBaseMs;

    if (needs.fatigue > 0.7) {
      delay += ((needs.fatigue - 0.7) / 0.3 *
              LumaConstants.replyDelayFatigueExtraMs)
          .round();
    }

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

class _EmotionDelta {
  final double valence;
  final double arousal;
  const _EmotionDelta(this.valence, this.arousal);
}
