import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/time_simulator.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

void main() {
  late TimeSimulator simulator;

  setUp(() {
    simulator = TimeSimulator();
  });

  PetState _makePet({int minutesAgo = 60}) => PetState(
        id: 'test-pet',
        name: 'TestLuma',
        birthday: DateTime.now().subtract(const Duration(days: 7)),
        personality: {
          'openness': 0.5,
          'conscientiousness': 0.5,
          'extraversion': 0.5,
          'agreeableness': 0.5,
          'neuroticism': 0.5,
        },
        needs: Needs(loneliness: 0.3, curiosity: 0.5, fatigue: 0.2),
        emotion: Emotion(valence: 0.2, arousal: 0.3),
        lastActiveAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );

  group('TimeSimulator', () {
    test('short absence barely changes state', () {
      final pet = _makePet(minutesAgo: 5);
      final result = simulator.simulate(pet, 5);
      // Loneliness should increase only slightly.
      expect(result.state.needs.loneliness, closeTo(0.3, 0.15));
      expect(result.diaryEntries, isEmpty);
      expect(result.reunionMood, ReunionMood.brief);
    });

    test('1-hour absence increases loneliness noticeably', () {
      final pet = _makePet(minutesAgo: 60);
      final result = simulator.simulate(pet, 60);
      expect(result.state.needs.loneliness, greaterThan(0.3));
      expect(result.reunionMood, ReunionMood.normalReturn);
    });

    test('24-hour absence causes significant loneliness', () {
      final pet = _makePet(minutesAgo: 1440);
      final result = simulator.simulate(pet, 1440);
      expect(result.state.needs.loneliness, greaterThan(0.7));
      expect(result.reunionMood, ReunionMood.longApart);
    });

    test('generates diary entries for long absences', () {
      final pet = _makePet(minutesAgo: 1440); // 24 hours
      final result = simulator.simulate(pet, 1440);
      // Should have at least 1 diary entry for 24h.
      expect(result.diaryEntries.length, greaterThanOrEqualTo(1));
    });

    test('caps simulation to max hours', () {
      final pet = _makePet(minutesAgo: 99999);
      final result = simulator.simulate(pet, 99999);
      // Should be capped, not crash.
      expect(result.elapsedMinutes, lessThanOrEqualTo(72 * 60));
    });
  });
}
