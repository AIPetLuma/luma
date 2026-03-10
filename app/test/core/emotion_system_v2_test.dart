import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/emotion_system.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';

void main() {
  late EmotionSystem system;

  setUp(() {
    system = EmotionSystem();
  });

  // ════════════════════════════════════════════════════════
  // 情绪惯性（Emotional Inertia）
  // ════════════════════════════════════════════════════════

  group('Emotional inertia', () {
    test('extreme emotion resists change more than mild emotion', () {
      // Very negative valence — should be harder to push positive
      final veryNeg = Emotion(valence: -0.8, arousal: 0.3);
      final mildNeg = Emotion(valence: -0.2, arousal: 0.3);

      final afterVeryNeg = system.onEvent(veryNeg, EmotionEvent.positiveChat);
      final afterMildNeg = system.onEvent(mildNeg, EmotionEvent.positiveChat);

      final deltaVeryNeg = afterVeryNeg.valence - veryNeg.valence;
      final deltaMildNeg = afterMildNeg.valence - mildNeg.valence;

      // More extreme emotion → smaller actual change
      expect(deltaVeryNeg, lessThan(deltaMildNeg));
    });

    test('withdrawn pet does not instantly become excited on reunion', () {
      final withdrawn = Emotion(valence: -0.8, arousal: 0.1);
      final after = system.onEvent(withdrawn, EmotionEvent.userReturned);
      // Should NOT jump to positive valence in one event
      expect(after.valence, lessThan(0.0));
    });

    test('mild emotion shifts easily', () {
      final neutral = Emotion(valence: 0.0, arousal: 0.3);
      final after = system.onEvent(neutral, EmotionEvent.positiveChat);
      // Should shift close to the full delta
      expect(after.valence, greaterThan(0.05));
    });
  });

  // ════════════════════════════════════════════════════════
  // 事件疲劳（Event Fatigue / Habituation）
  // ════════════════════════════════════════════════════════

  group('Event fatigue / habituation', () {
    test('repeated same events have diminishing impact', () {
      var emotion = Emotion(valence: 0.0, arousal: 0.3);
      final impacts = <double>[];

      for (int i = 0; i < 6; i++) {
        final before = emotion.valence;
        emotion = system.onEvent(emotion, EmotionEvent.positiveChat);
        impacts.add(emotion.valence - before);
      }

      // First event should have more impact than the 5th
      expect(impacts[0], greaterThan(impacts[4]));
    });

    test('different event types are not fatigued by each other', () {
      var emotion = Emotion(valence: 0.0, arousal: 0.3);

      // Fire positiveChat 5 times to build fatigue
      for (int i = 0; i < 5; i++) {
        emotion = system.onEvent(emotion, EmotionEvent.positiveChat);
      }
      final beforeNewTopic = emotion.valence;
      // Now fire a different event — should NOT be fatigued
      emotion = system.onEvent(emotion, EmotionEvent.newTopicShared);
      final newTopicDelta = emotion.valence - beforeNewTopic;

      // newTopicShared impact should still be close to full
      expect(newTopicDelta, greaterThan(0.02));
    });

    test('event fatigue resets over time via resetEventFatigue', () {
      var emotion = Emotion(valence: 0.0, arousal: 0.3);

      // Build up fatigue
      for (int i = 0; i < 5; i++) {
        emotion = system.onEvent(emotion, EmotionEvent.positiveChat);
      }

      // Reset fatigue (simulates time passing)
      system.resetEventFatigue();

      final before = emotion.valence;
      emotion = system.onEvent(emotion, EmotionEvent.positiveChat);
      final freshDelta = emotion.valence - before;

      // After reset, impact should be closer to original
      expect(freshDelta, greaterThan(0.03));
    });
  });

  // ════════════════════════════════════════════════════════
  // 需求交互效应（Cross-Need Emotion Effects）
  // ════════════════════════════════════════════════════════

  group('Cross-need interaction effects', () {
    test('high loneliness + high curiosity produces different emotion than high loneliness + low curiosity', () {
      final lonelyCurious = Needs(loneliness: 0.9, curiosity: 0.8);
      final lonelyBored = Needs(loneliness: 0.9, curiosity: 0.1);
      final base = Emotion(valence: 0.0, arousal: 0.5);

      final afterCurious = system.tick(base, lonelyCurious, 30);
      final afterBored = system.tick(base, lonelyBored, 30);

      // Lonely+curious → higher arousal (restless) vs lonely+bored → lower arousal
      expect(afterCurious.arousal, greaterThan(afterBored.arousal));
    });
  });

  // ════════════════════════════════════════════════════════
  // 向后兼容
  // ════════════════════════════════════════════════════════

  group('Backward compatibility', () {
    test('emotion decays toward baseline over time', () {
      final happy = Emotion(valence: 0.9, arousal: 0.9);
      final after = system.tick(happy, Needs(), 60);
      expect(after.valence, lessThan(0.9));
      expect(after.arousal, lessThan(0.9));
    });

    test('high loneliness lowers valence', () {
      final neutral = Emotion(valence: 0.3, arousal: 0.3);
      final lonely = Needs(loneliness: 0.9);
      final after = system.tick(neutral, lonely, 30);
      expect(after.valence, lessThan(0.3));
    });

    test('harmDetected significantly drops valence', () {
      final ok = Emotion(valence: 0.3, arousal: 0.4);
      final after = system.onEvent(ok, EmotionEvent.harmDetected);
      expect(after.valence, lessThan(0.0));
    });

    test('sad emotion produces shorter max tokens', () {
      final sad = Emotion(valence: -0.5, arousal: 0.2);
      expect(system.suggestedMaxTokens(sad), 150);
    });
  });
}
