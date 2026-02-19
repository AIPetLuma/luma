import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/emotion_system.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';

void main() {
  late EmotionSystem system;

  setUp(() {
    system = EmotionSystem();
  });

  group('EmotionSystem.tick', () {
    test('emotion decays toward baseline over time', () {
      final happy = Emotion(valence: 0.9, arousal: 0.9);
      final needs = Needs();
      final after = system.tick(happy, needs, 60); // 1 hour
      expect(after.valence, lessThan(0.9));
      expect(after.arousal, lessThan(0.9));
    });

    test('high loneliness lowers valence', () {
      final neutral = Emotion(valence: 0.3, arousal: 0.3);
      final lonely = Needs(loneliness: 0.9);
      final after = system.tick(neutral, lonely, 30);
      expect(after.valence, lessThan(0.3));
    });

    test('high fatigue lowers arousal', () {
      final alert = Emotion(valence: 0.3, arousal: 0.7);
      final tired = Needs(fatigue: 0.9);
      final after = system.tick(alert, tired, 30);
      expect(after.arousal, lessThan(0.7));
    });

    test('low security increases anxiety (low valence, higher arousal)', () {
      final calm = Emotion(valence: 0.2, arousal: 0.3);
      final insecure = Needs(security: 0.1);
      final after = system.tick(calm, insecure, 30);
      expect(after.valence, lessThan(0.2));
    });
  });

  group('EmotionSystem.onEvent', () {
    test('userReturned boosts valence and arousal', () {
      final lonely = Emotion(valence: -0.2, arousal: 0.2);
      final after = system.onEvent(lonely, EmotionEvent.userReturned);
      expect(after.valence, greaterThan(-0.2));
      expect(after.arousal, greaterThan(0.2));
    });

    test('harmDetected significantly drops valence', () {
      final ok = Emotion(valence: 0.3, arousal: 0.4);
      final after = system.onEvent(ok, EmotionEvent.harmDetected);
      expect(after.valence, lessThan(0.0));
    });

    test('positiveChat improves mood', () {
      final neutral = Emotion(valence: 0.0, arousal: 0.3);
      final after = system.onEvent(neutral, EmotionEvent.positiveChat);
      expect(after.valence, greaterThan(0.0));
    });
  });

  group('Emotion.label', () {
    test('maps correctly to emotion labels', () {
      expect(Emotion(valence: 0.7, arousal: 0.7).label, 'excited');
      expect(Emotion(valence: 0.5, arousal: 0.2).label, 'content');
      expect(Emotion(valence: -0.6, arousal: 0.1).label, 'melancholy');
      expect(Emotion(valence: -0.8, arousal: 0.1).label, 'withdrawn');
    });
  });

  group('EmotionSystem reply tuning', () {
    test('sad emotion produces shorter max tokens', () {
      final sad = Emotion(valence: -0.5, arousal: 0.2);
      expect(system.suggestedMaxTokens(sad), 150);
    });

    test('happy emotion produces longer max tokens', () {
      final happy = Emotion(valence: 0.5, arousal: 0.6);
      expect(system.suggestedMaxTokens(happy), 400);
    });
  });
}
