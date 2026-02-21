import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/time_simulator.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

// Test Scope (EN):
// - Validate offline simulation behavior by duration bucket.
// - Validate reunion mood classification and diary generation.
// - Validate upper-bound protection on simulation length.
//
// 测试范围（中文）：
// - 按离线时长分桶，验证离线模拟行为。
// - 验证重逢情绪分类与日记生成逻辑。
// - 验证模拟时长上限保护，避免极端输入导致异常。
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
    // EN: very short absence should not drastically mutate state.
    // 中文：极短离开不应显著改变宠物状态。
    test('short absence barely changes state', () {
      final pet = _makePet(minutesAgo: 5);
      final result = simulator.simulate(pet, 5);
      // Loneliness should increase only slightly.
      expect(result.state.needs.loneliness, closeTo(0.3, 0.15));
      expect(result.diaryEntries, isEmpty);
      expect(result.reunionMood, ReunionMood.brief);
    });

    // EN: 1-hour gap should increase loneliness but remain normal reunion.
    // 中文：1 小时离开应提升孤独值，但重逢仍属常规状态。
    test('1-hour absence increases loneliness noticeably', () {
      final pet = _makePet(minutesAgo: 60);
      final result = simulator.simulate(pet, 60);
      expect(result.state.needs.loneliness, greaterThan(0.3));
      expect(result.reunionMood, ReunionMood.normalReturn);
    });

    // EN: 24-hour gap should push loneliness high and trigger needy reunion.
    // 中文：24 小时离开应使孤独值明显升高，并触发依赖型重逢。
    test('24-hour absence causes significant loneliness', () {
      final pet = _makePet(minutesAgo: 1440);
      final result = simulator.simulate(pet, 1440);
      expect(result.state.needs.loneliness, greaterThan(0.7));
      expect(result.reunionMood, ReunionMood.needyReunion);
    });

    // EN: long absences should create at least one diary artifact.
    // 中文：长时间离开应至少生成一条日记产物。
    test('generates diary entries for long absences', () {
      final pet = _makePet(minutesAgo: 1440); // 24 hours
      final result = simulator.simulate(pet, 1440);
      // Should have at least 1 diary entry for 24h.
      expect(result.diaryEntries.length, greaterThanOrEqualTo(1));
    });

    // EN: huge durations must be capped to product maximum.
    // 中文：超大离线时长必须被上限截断。
    test('caps simulation to max hours', () {
      final pet = _makePet(minutesAgo: 99999);
      final result = simulator.simulate(pet, 99999);
      // Should be capped, not crash.
      expect(result.elapsedMinutes, lessThanOrEqualTo(72 * 60));
    });
  });
}
