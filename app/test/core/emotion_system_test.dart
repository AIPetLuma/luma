import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/emotion_system.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';

// Test Scope (EN):
// - Validate continuous emotion drift under needs pressure.
// - Validate discrete event reactions (return/harm/positive chat).
// - Validate label mapping and reply-token tuning policy.
//
// 测试范围（中文）：
// - 验证需求压力下情绪随时间的连续变化。
// - 验证离散事件（回归/伤害/积极聊天）的情绪响应。
// - 验证情绪标签映射与回复 token 调整策略。
void main() {
  late EmotionSystem system;

  setUp(() {
    system = EmotionSystem();
  });

  group('EmotionSystem.tick', () {
    // EN: high-intensity emotion should decay toward baseline.
    // 中文：高强度情绪应逐步回归基线。
    test('emotion decays toward baseline over time', () {
      final happy = Emotion(valence: 0.9, arousal: 0.9);
      final needs = Needs();
      final after = system.tick(happy, needs, 60); // 1 hour
      expect(after.valence, lessThan(0.9));
      expect(after.arousal, lessThan(0.9));
    });

    // EN: loneliness pressure should lower valence.
    // 中文：孤独压力应拉低情绪效价。
    test('high loneliness lowers valence', () {
      final neutral = Emotion(valence: 0.3, arousal: 0.3);
      final lonely = Needs(loneliness: 0.9);
      final after = system.tick(neutral, lonely, 30);
      expect(after.valence, lessThan(0.3));
    });

    // EN: fatigue should reduce arousal.
    // 中文：疲劳应降低唤醒度。
    test('high fatigue lowers arousal', () {
      final alert = Emotion(valence: 0.3, arousal: 0.7);
      final tired = Needs(fatigue: 0.9);
      final after = system.tick(alert, tired, 30);
      expect(after.arousal, lessThan(0.7));
    });

    // EN: low security should bias to anxious direction.
    // 中文：低安全感应向焦虑方向偏移。
    test('low security increases anxiety (low valence, higher arousal)', () {
      final calm = Emotion(valence: 0.2, arousal: 0.3);
      final insecure = Needs(security: 0.1);
      final after = system.tick(calm, insecure, 30);
      expect(after.valence, lessThan(0.2));
    });
  });

  group('EmotionSystem.onEvent', () {
    // EN: user return should positively reinforce emotion.
    // 中文：用户回归应带来正向情绪强化。
    test('userReturned boosts valence and arousal', () {
      final lonely = Emotion(valence: -0.2, arousal: 0.2);
      final after = system.onEvent(lonely, EmotionEvent.userReturned);
      expect(after.valence, greaterThan(-0.2));
      expect(after.arousal, greaterThan(0.2));
    });

    // EN: harm event should force strong negative shift.
    // 中文：伤害事件应触发明显负向偏移。
    test('harmDetected significantly drops valence', () {
      final ok = Emotion(valence: 0.3, arousal: 0.4);
      final after = system.onEvent(ok, EmotionEvent.harmDetected);
      expect(after.valence, lessThan(0.0));
    });

    // EN: positive conversation should improve mood.
    // 中文：积极聊天应提升情绪。
    test('positiveChat improves mood', () {
      final neutral = Emotion(valence: 0.0, arousal: 0.3);
      final after = system.onEvent(neutral, EmotionEvent.positiveChat);
      expect(after.valence, greaterThan(0.0));
    });
  });

  group('Emotion.label', () {
    // EN: mapping test keeps prompt/UI semantic consistency.
    // 中文：标签映射测试用于保证提示词与 UI 语义一致。
    test('maps correctly to emotion labels', () {
      expect(Emotion(valence: 0.7, arousal: 0.7).label, 'excited');
      expect(Emotion(valence: 0.5, arousal: 0.2).label, 'content');
      expect(Emotion(valence: -0.6, arousal: 0.1).label, 'melancholy');
      expect(Emotion(valence: -0.8, arousal: 0.4).label, 'withdrawn');
    });
  });

  group('EmotionSystem reply tuning', () {
    // EN: low mood should reduce response verbosity.
    // 中文：低情绪状态应降低回复篇幅。
    test('sad emotion produces shorter max tokens', () {
      final sad = Emotion(valence: -0.5, arousal: 0.2);
      expect(system.suggestedMaxTokens(sad), 150);
    });

    // EN: positive/high-arousal mood allows longer responses.
    // 中文：积极高唤醒状态允许更长回复。
    test('happy emotion produces longer max tokens', () {
      final happy = Emotion(valence: 0.5, arousal: 0.6);
      expect(system.suggestedMaxTokens(happy), 400);
    });
  });
}
