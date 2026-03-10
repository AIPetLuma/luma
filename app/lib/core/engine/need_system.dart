import 'dart:math';
import '../../data/models/need.dart';
import '../../shared/constants.dart';

/// Manages the four fundamental needs that drive Luma's behaviour.
///
/// Needs drift over time (simulating a living creature) and are
/// satisfied by specific user interactions. This is the foundation
/// of the "it runs while you're away" experience.
///
/// V2 enhancements:
/// - Need coupling (needs influence each other)
/// - Circadian rhythm (time-of-day modulation)
/// - Personality modulation (traits affect drift rates)
/// - Diminishing returns on interaction
class NeedSystem {
  final Random _rng;

  /// Tracks recent interaction count for diminishing returns.
  int _recentInteractionCount = 0;

  NeedSystem({Random? random}) : _rng = random ?? Random();

  /// Advance needs by [minutes] of elapsed time.
  ///
  /// Backward-compatible: uses current hour for circadian rhythm.
  Needs tick(Needs current, double minutes, {bool isInteracting = false}) {
    return _tickInternal(
      current, minutes,
      isInteracting: isInteracting,
      hourOfDay: DateTime.now().hour,
      personality: null,
    );
  }

  /// Tick with explicit time-of-day (for testing circadian rhythm).
  Needs tickAt(Needs current, double minutes, {
    bool isInteracting = false,
    required int hourOfDay,
  }) {
    return _tickInternal(
      current, minutes,
      isInteracting: isInteracting,
      hourOfDay: hourOfDay,
      personality: null,
    );
  }

  /// Tick with personality modulation.
  Needs tickWithPersonality(Needs current, double minutes, {
    bool isInteracting = false,
    required Map<String, double> personality,
    int? hourOfDay,
  }) {
    return _tickInternal(
      current, minutes,
      isInteracting: isInteracting,
      hourOfDay: hourOfDay ?? DateTime.now().hour,
      personality: personality,
    );
  }

  Needs _tickInternal(Needs current, double minutes, {
    required bool isInteracting,
    required int hourOfDay,
    Map<String, double>? personality,
  }) {
    final n = current.copyWith();

    // Extract personality traits (default 0.5 for neutral)
    final extraversion = personality?['extraversion'] ?? 0.5;
    final neuroticism = personality?['neuroticism'] ?? 0.5;
    final openness = personality?['openness'] ?? 0.5;

    // ── Circadian factors ──
    final circadianFatigue = _circadianFatigueFactor(hourOfDay);
    final circadianCuriosity = _circadianCuriosityFactor(hourOfDay);

    // ── Loneliness ──
    if (isInteracting) {
      n.loneliness -= 0.005 * minutes;
    } else {
      // Personality: extraverts get lonely faster
      final extraversionMod = 1.0 + (extraversion - 0.5) * 0.4;
      // Coupling: low security accelerates loneliness
      final securityCoupling = n.security < 0.3
          ? 1.0 + (0.3 - n.security) * 1.0
          : 1.0;
      n.loneliness += LumaConstants.lonelinessOfflineDrift
          * minutes * extraversionMod * securityCoupling;
    }

    // ── Curiosity ──
    // Personality: openness amplifies curiosity drift
    final opennessMod = 0.5 + openness;
    final curiosityNoise =
        (_rng.nextDouble() - 0.5) * 2 * LumaConstants.curiosityDriftRange
        * opennessMod * circadianCuriosity;
    final meanReversion = (0.5 - n.curiosity) * 0.002;
    n.curiosity += (curiosityNoise + meanReversion) * minutes;
    // Coupling: high loneliness suppresses curiosity
    if (n.loneliness > 0.7) {
      n.curiosity -= (n.loneliness - 0.7) * 0.003 * minutes;
    }

    // ── Fatigue ──
    if (isInteracting) {
      var fatigueDrift = LumaConstants.fatigueDriftActive;
      // Coupling: high curiosity accelerates fatigue (exploring costs energy)
      if (n.curiosity > 0.6) {
        fatigueDrift += (n.curiosity - 0.6) * 0.002;
      }
      n.fatigue += fatigueDrift * minutes;
    } else {
      n.fatigue -= LumaConstants.fatigueRecoveryIdle * minutes;
    }
    // Circadian: fatigue drifts upward at night
    n.fatigue += circadianFatigue * minutes;

    // ── Security ──
    // Personality: neurotic pets lose security faster
    final neuroticismMod = 1.0 + (neuroticism - 0.5) * 0.6;
    n.security -= LumaConstants.securityNaturalDecay * minutes * neuroticismMod;
    // Coupling: high fatigue erodes security
    if (n.fatigue > 0.7) {
      n.security -= (n.fatigue - 0.7) * 0.002 * minutes;
    }

    n.clamp();
    return n;
  }

  /// Apply the effect of a single user interaction.
  /// Implements diminishing returns on repeated interactions.
  Needs onInteraction(Needs current, {required InteractionType type}) {
    final n = current.copyWith();
    _recentInteractionCount++;

    // Diminishing returns factor: first interactions have full effect,
    // later ones are attenuated.
    final diminish = 1.0 / (1.0 + _recentInteractionCount * 0.15);

    switch (type) {
      case InteractionType.chat:
        n.loneliness += LumaConstants.lonelinessPerInteraction * diminish;
        n.fatigue += 0.02;
        n.security += LumaConstants.securityPerPositive;
        break;

      case InteractionType.newTopic:
        n.loneliness += LumaConstants.lonelinessPerInteraction * diminish;
        n.curiosity += LumaConstants.curiosityPerNewTopic;
        n.security += LumaConstants.securityPerPositive;
        break;

      case InteractionType.positiveGesture:
        n.security += LumaConstants.securityPerPositive * 2;
        n.loneliness -= 0.1 * diminish;
        break;

      case InteractionType.negativeGesture:
        n.security += LumaConstants.securityPerNegative;
        n.loneliness += 0.1;
        break;

      case InteractionType.sleep:
        n.fatigue += LumaConstants.fatiguePerSleep;
        _recentInteractionCount = 0; // Reset after sleep
        break;
    }

    n.clamp();
    return n;
  }

  /// Reset the diminishing returns counter (e.g. after a session break).
  void resetInteractionCount() {
    _recentInteractionCount = 0;
  }

  // ── Threshold checks (unchanged) ──

  bool shouldReachOut(Needs needs) =>
      needs.loneliness >= LumaConstants.lonelinessPushThreshold;

  bool isTired(Needs needs) =>
      needs.fatigue >= LumaConstants.fatigueSlowdownThreshold;

  bool isInsecure(Needs needs) =>
      needs.security <= LumaConstants.securityWithdrawalThreshold;

  // ── Circadian helpers ──

  /// Returns a small fatigue bonus at night, negative during peak day hours.
  double _circadianFatigueFactor(int hour) {
    // Sinusoidal: peaks at ~3AM, trough at ~15:00
    return sin((hour - 15) * pi / 12) * 0.003;
  }

  /// Returns a curiosity multiplier: higher during day, lower at night.
  double _circadianCuriosityFactor(int hour) {
    // Peak at ~10AM, trough at ~2AM
    return 0.7 + 0.3 * cos((hour - 10) * pi / 12);
  }
}

enum InteractionType {
  chat,
  newTopic,
  positiveGesture,
  negativeGesture,
  sleep,
}
