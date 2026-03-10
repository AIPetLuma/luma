import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/need_system.dart';
import 'package:luma/data/models/need.dart';

void main() {
  late NeedSystem system;

  setUp(() {
    system = NeedSystem();
  });

  // ════════════════════════════════════════════════════════
  // 需求耦合（Need Coupling）
  // ════════════════════════════════════════════════════════

  group('Need coupling', () {
    test('high loneliness suppresses curiosity over time', () {
      final initial = Needs(loneliness: 0.9, curiosity: 0.6);
      final after = system.tick(initial, 60); // 1 hour
      // Coupling: loneliness > 0.7 should drag curiosity down
      expect(after.curiosity, lessThan(0.6));
    });

    test('high fatigue reduces security over time', () {
      final initial = Needs(fatigue: 0.85, security: 0.5);
      final after = system.tick(initial, 60);
      // Coupling: fatigue > 0.7 should accelerate security decay
      // Security should drop MORE than the base decay alone
      final baseDecayOnly = system.tick(
        Needs(fatigue: 0.2, security: 0.5), 60,
      );
      expect(after.security, lessThan(baseDecayOnly.security));
    });

    test('high curiosity accelerates fatigue during interaction', () {
      final curious = Needs(curiosity: 0.8, fatigue: 0.3);
      final notCurious = Needs(curiosity: 0.2, fatigue: 0.3);
      final afterCurious = system.tick(curious, 30, isInteracting: true);
      final afterNotCurious = system.tick(notCurious, 30, isInteracting: true);
      // Exploring (high curiosity) costs more energy
      expect(afterCurious.fatigue, greaterThan(afterNotCurious.fatigue));
    });

    test('low security accelerates loneliness growth', () {
      final insecure = Needs(loneliness: 0.4, security: 0.1);
      final secure = Needs(loneliness: 0.4, security: 0.8);
      final afterInsecure = system.tick(insecure, 60);
      final afterSecure = system.tick(secure, 60);
      // Insecure pet gets lonely faster
      expect(afterInsecure.loneliness, greaterThan(afterSecure.loneliness));
    });
  });

  // ════════════════════════════════════════════════════════
  // 昼夜节律（Circadian Rhythm）
  // ════════════════════════════════════════════════════════

  group('Circadian rhythm', () {
    test('fatigue drift is higher at night than during the day', () {
      final initial = Needs(fatigue: 0.3);
      // Night tick (3 AM)
      final nightResult = system.tickAt(initial, 60, hourOfDay: 3);
      // Day tick (14:00)
      final dayResult = system.tickAt(initial, 60, hourOfDay: 14);
      // Night should produce higher fatigue
      expect(nightResult.fatigue, greaterThan(dayResult.fatigue));
    });

    test('curiosity peaks during afternoon', () {
      // Run multiple times and check average to account for randomness
      double morningAvg = 0;
      double nightAvg = 0;
      for (int i = 0; i < 100; i++) {
        morningAvg += system.tickAt(Needs(curiosity: 0.5), 30, hourOfDay: 10).curiosity;
        nightAvg += system.tickAt(Needs(curiosity: 0.5), 30, hourOfDay: 2).curiosity;
      }
      morningAvg /= 100;
      nightAvg /= 100;
      // Daytime curiosity should trend slightly higher on average
      expect(morningAvg, greaterThan(nightAvg));
    });
  });

  // ════════════════════════════════════════════════════════
  // 人格调制（Personality Modulation）
  // ════════════════════════════════════════════════════════

  group('Personality modulation', () {
    test('extraverted pet gets lonely faster than introverted', () {
      final personality = {'extraversion': 0.8, 'neuroticism': 0.5};
      final introverted = {'extraversion': 0.2, 'neuroticism': 0.5};
      final initial = Needs(loneliness: 0.3);

      final afterExtraverted = system.tickWithPersonality(
        initial, 60, personality: personality,
      );
      final afterIntroverted = system.tickWithPersonality(
        initial, 60, personality: introverted,
      );
      expect(afterExtraverted.loneliness, greaterThan(afterIntroverted.loneliness));
    });

    test('high neuroticism pet loses security faster', () {
      final anxious = {'neuroticism': 0.8, 'extraversion': 0.5};
      final calm = {'neuroticism': 0.2, 'extraversion': 0.5};
      final initial = Needs(security: 0.6);

      final afterAnxious = system.tickWithPersonality(
        initial, 60, personality: anxious,
      );
      final afterCalm = system.tickWithPersonality(
        initial, 60, personality: calm,
      );
      expect(afterAnxious.security, lessThan(afterCalm.security));
    });

    test('high openness pet has more curiosity drift', () {
      final open = {'openness': 0.9, 'extraversion': 0.5};
      final closed = {'openness': 0.1, 'extraversion': 0.5};

      // Average over many runs to account for randomness
      double openAvg = 0;
      double closedAvg = 0;
      for (int i = 0; i < 200; i++) {
        openAvg += system.tickWithPersonality(
          Needs(curiosity: 0.5), 30, personality: open,
        ).curiosity;
        closedAvg += system.tickWithPersonality(
          Needs(curiosity: 0.5), 30, personality: closed,
        ).curiosity;
      }
      openAvg /= 200;
      closedAvg /= 200;
      // High openness → more curiosity variance → higher average deviation from 0.5
      // The absolute difference from 0.5 should be larger for open personality
      expect((openAvg - 0.5).abs(), greaterThan((closedAvg - 0.5).abs() * 0.5));
    });
  });

  // ════════════════════════════════════════════════════════
  // 边际递减（Diminishing Returns）
  // ════════════════════════════════════════════════════════

  group('Diminishing returns on interaction', () {
    test('repeated chats have diminishing loneliness reduction', () {
      var needs = Needs(loneliness: 0.9);
      final reductions = <double>[];

      for (int i = 0; i < 5; i++) {
        final before = needs.loneliness;
        needs = system.onInteraction(needs, type: InteractionType.chat);
        reductions.add(before - needs.loneliness);
      }

      // First interaction should reduce loneliness more than the 5th
      expect(reductions.first, greaterThan(reductions.last));
    });
  });

  // ════════════════════════════════════════════════════════
  // 向后兼容（Backward Compatibility）
  // ════════════════════════════════════════════════════════

  group('Backward compatibility — original tests still pass', () {
    test('loneliness increases when offline', () {
      final initial = Needs(loneliness: 0.5);
      final after = system.tick(initial, 60);
      expect(after.loneliness, greaterThan(0.5));
    });

    test('loneliness decreases when interacting', () {
      final initial = Needs(loneliness: 0.5);
      final after = system.tick(initial, 10, isInteracting: true);
      expect(after.loneliness, lessThan(0.5));
    });

    test('fatigue increases during interaction', () {
      final initial = Needs(fatigue: 0.3);
      final after = system.tick(initial, 30, isInteracting: true);
      expect(after.fatigue, greaterThan(0.3));
    });

    test('fatigue recovers when idle', () {
      final initial = Needs(fatigue: 0.8);
      final after = system.tick(initial, 60);
      expect(after.fatigue, lessThan(0.8));
    });

    test('values are clamped to 0.0-1.0', () {
      final extreme = Needs(loneliness: 0.99, fatigue: 0.01);
      final after = system.tick(extreme, 1000);
      expect(after.loneliness, lessThanOrEqualTo(1.0));
      expect(after.fatigue, greaterThanOrEqualTo(0.0));
    });

    test('chat reduces loneliness', () {
      final initial = Needs(loneliness: 0.7);
      final after = system.onInteraction(initial, type: InteractionType.chat);
      expect(after.loneliness, lessThan(0.7));
    });

    test('shouldReachOut when very lonely', () {
      expect(system.shouldReachOut(Needs(loneliness: 0.9)), isTrue);
      expect(system.shouldReachOut(Needs(loneliness: 0.5)), isFalse);
    });
  });
}
