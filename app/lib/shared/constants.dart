/// Global constants for the Luma app.
class LumaConstants {
  LumaConstants._();

  // ── Engine tick ──
  static const tickIntervalSeconds = 60;
  static const maxOfflineSimulationHours = 72;

  // ── Need drift rates (per minute) ──
  static const lonelinessOfflineDrift = 0.01;
  static const lonelinessOnlineIdleDrift = 0.003;
  static const curiosityDriftRange = 0.005;
  static const fatigueDriftActive = 0.002;
  static const fatigueRecoveryIdle = 0.01;
  static const securityNaturalDecay = 0.001;

  // ── Need interaction deltas ──
  static const lonelinessPerInteraction = -0.3;
  static const curiosityPerNewTopic = -0.2;
  static const fatiguePerSleep = -0.5;
  static const securityPerPositive = 0.05;
  static const securityPerNegative = -0.15;

  // ── Need thresholds ──
  static const lonelinessPushThreshold = 0.8;
  static const fatigueSlowdownThreshold = 0.9;
  static const securityWithdrawalThreshold = 0.3;

  // ── Emotion ──
  static const emotionDecayRate = 0.005; // per minute, toward baseline
  static const emotionBaselineValence = 0.2;
  static const emotionBaselineArousal = 0.3;

  // ── Memory ──
  static const workingMemoryMaxRounds = 20;
  static const shortTermMemoryDays = 30;
  static const memoryContextMaxTokens = 500;

  // ── Chat ──
  static const defaultMaxTokens = 300;
  static const happyMaxTokens = 400;
  static const sadMaxTokens = 150;
  static const baseTemperature = 0.7;
  static const replyDelayBaseMs = 500;
  static const replyDelayFatigueExtraMs = 5000;

  // ── Compliance ──
  static const disclosureIntervalMinutes = 180; // 3 hours
  static const crisisHotlineUS = '988';
  static const crisisTextLine = 'Text HOME to 741741';
  static const crisisWebsite = 'https://988lifeline.org';

  // ── LLM ──
  static const defaultModel = 'claude-haiku-4-5-20251001';
  static const qualityModel = 'claude-sonnet-4-5-20250929';
}
