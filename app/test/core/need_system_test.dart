import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/need_system.dart';
import 'package:luma/data/models/need.dart';

void main() {
  late NeedSystem system;

  setUp(() {
    system = NeedSystem();
  });

  group('NeedSystem.tick', () {
    test('loneliness increases when offline', () {
      final initial = Needs(loneliness: 0.5);
      final after = system.tick(initial, 60); // 1 hour offline
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
      final after = system.tick(initial, 60); // 1 hour idle
      expect(after.fatigue, lessThan(0.8));
    });

    test('values are clamped to 0.0-1.0', () {
      final extreme = Needs(loneliness: 0.99, fatigue: 0.01);
      final after = system.tick(extreme, 1000); // long time
      expect(after.loneliness, lessThanOrEqualTo(1.0));
      expect(after.fatigue, greaterThanOrEqualTo(0.0));
    });
  });

  group('NeedSystem.onInteraction', () {
    test('chat reduces loneliness', () {
      final initial = Needs(loneliness: 0.7);
      final after = system.onInteraction(initial, type: InteractionType.chat);
      expect(after.loneliness, lessThan(0.7));
    });

    test('negative gesture reduces security', () {
      final initial = Needs(security: 0.5);
      final after = system.onInteraction(
        initial,
        type: InteractionType.negativeGesture,
      );
      expect(after.security, lessThan(0.5));
    });

    test('sleep reduces fatigue significantly', () {
      final initial = Needs(fatigue: 0.8);
      final after = system.onInteraction(initial, type: InteractionType.sleep);
      expect(after.fatigue, lessThan(0.5));
    });
  });

  group('NeedSystem.thresholds', () {
    test('shouldReachOut when very lonely', () {
      expect(system.shouldReachOut(Needs(loneliness: 0.9)), isTrue);
      expect(system.shouldReachOut(Needs(loneliness: 0.5)), isFalse);
    });

    test('isTired when very fatigued', () {
      expect(system.isTired(Needs(fatigue: 0.95)), isTrue);
      expect(system.isTired(Needs(fatigue: 0.5)), isFalse);
    });

    test('isInsecure when trust is low', () {
      expect(system.isInsecure(Needs(security: 0.1)), isTrue);
      expect(system.isInsecure(Needs(security: 0.5)), isFalse);
    });
  });
}
