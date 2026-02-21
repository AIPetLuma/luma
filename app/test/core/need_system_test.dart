import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/need_system.dart';
import 'package:luma/data/models/need.dart';

// Test Scope (EN):
// - Validate need state transitions while offline/interactive.
// - Validate interaction event effects and threshold helpers.
// - Keep assertions behavior-oriented (not implementation-specific constants).
//
// 测试范围（中文）：
// - 校验离线/互动时需求值的状态迁移。
// - 校验交互事件对需求值的影响与阈值判断。
// - 断言聚焦行为结果，避免绑定内部实现常量。
void main() {
  late NeedSystem system;

  setUp(() {
    system = NeedSystem();
  });

  group('NeedSystem.tick', () {
    // EN: offline time should increase loneliness.
    // 中文：离线时间推进后，孤独值应上升。
    test('loneliness increases when offline', () {
      final initial = Needs(loneliness: 0.5);
      final after = system.tick(initial, 60); // 1 hour offline
      expect(after.loneliness, greaterThan(0.5));
    });

    // EN: active interaction should reduce loneliness.
    // 中文：发生互动时，孤独值应下降。
    test('loneliness decreases when interacting', () {
      final initial = Needs(loneliness: 0.5);
      final after = system.tick(initial, 10, isInteracting: true);
      expect(after.loneliness, lessThan(0.5));
    });

    // EN: interaction consumes energy and increases fatigue.
    // 中文：互动会消耗精力，疲劳值应上升。
    test('fatigue increases during interaction', () {
      final initial = Needs(fatigue: 0.3);
      final after = system.tick(initial, 30, isInteracting: true);
      expect(after.fatigue, greaterThan(0.3));
    });

    // EN: idle time should recover fatigue.
    // 中文：空闲时段应降低疲劳。
    test('fatigue recovers when idle', () {
      final initial = Needs(fatigue: 0.8);
      final after = system.tick(initial, 60); // 1 hour idle
      expect(after.fatigue, lessThan(0.8));
    });

    // EN: all need values must stay in [0,1].
    // 中文：需求值必须始终落在 [0,1] 区间。
    test('values are clamped to 0.0-1.0', () {
      final extreme = Needs(loneliness: 0.99, fatigue: 0.01);
      final after = system.tick(extreme, 1000); // long time
      expect(after.loneliness, lessThanOrEqualTo(1.0));
      expect(after.fatigue, greaterThanOrEqualTo(0.0));
    });
  });

  group('NeedSystem.onInteraction', () {
    // EN: chat is expected to satisfy companionship need.
    // 中文：聊天应缓解陪伴需求（降低孤独）。
    test('chat reduces loneliness', () {
      final initial = Needs(loneliness: 0.7);
      final after = system.onInteraction(initial, type: InteractionType.chat);
      expect(after.loneliness, lessThan(0.7));
    });

    // EN: negative gestures should reduce security.
    // 中文：负向手势应降低安全感。
    test('negative gesture reduces security', () {
      final initial = Needs(security: 0.5);
      final after = system.onInteraction(
        initial,
        type: InteractionType.negativeGesture,
      );
      expect(after.security, lessThan(0.5));
    });

    // EN: sleep interaction should provide strong fatigue recovery.
    // 中文：睡眠交互应显著恢复疲劳。
    test('sleep reduces fatigue significantly', () {
      final initial = Needs(fatigue: 0.8);
      final after = system.onInteraction(initial, type: InteractionType.sleep);
      expect(after.fatigue, lessThan(0.5));
    });
  });

  group('NeedSystem.thresholds', () {
    // EN: reach-out decision should trigger only when loneliness is high.
    // 中文：仅当孤独值足够高时才触发主动触达。
    test('shouldReachOut when very lonely', () {
      expect(system.shouldReachOut(Needs(loneliness: 0.9)), isTrue);
      expect(system.shouldReachOut(Needs(loneliness: 0.5)), isFalse);
    });

    // EN: tired threshold should capture severe fatigue only.
    // 中文：疲劳阈值应主要覆盖高疲劳状态。
    test('isTired when very fatigued', () {
      expect(system.isTired(Needs(fatigue: 0.95)), isTrue);
      expect(system.isTired(Needs(fatigue: 0.5)), isFalse);
    });

    // EN: insecurity helper should flag low-security states.
    // 中文：低安全感状态应被 isInsecure 正确识别。
    test('isInsecure when trust is low', () {
      expect(system.isInsecure(Needs(security: 0.1)), isTrue);
      expect(system.isInsecure(Needs(security: 0.5)), isFalse);
    });
  });
}
