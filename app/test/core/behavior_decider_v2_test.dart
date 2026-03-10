import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/behavior_decider.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/pet_state.dart';

PetState _makePet({
  double loneliness = 0.5,
  double curiosity = 0.5,
  double fatigue = 0.2,
  double security = 0.5,
  double valence = 0.2,
  double arousal = 0.3,
  double extraversion = 0.5,
}) =>
    PetState(
      id: 'test-pet',
      name: 'TestLuma',
      birthday: DateTime.now().subtract(const Duration(days: 30)),
      personality: {
        'openness': 0.5,
        'conscientiousness': 0.5,
        'extraversion': extraversion,
        'agreeableness': 0.5,
        'neuroticism': 0.5,
      },
      needs: Needs(
        loneliness: loneliness,
        curiosity: curiosity,
        fatigue: fatigue,
        security: security,
      ),
      emotion: Emotion(valence: valence, arousal: arousal),
      lastActiveAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

void main() {
  // ════════════════════════════════════════════════════════
  // 概率化决策（Probabilistic Decisions）
  // ════════════════════════════════════════════════════════

  group('Probabilistic reachOut', () {
    test('loneliness 0.9 triggers reachOut most of the time', () {
      final pet = _makePet(loneliness: 0.9);
      int reachOutCount = 0;
      for (int i = 0; i < 100; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(pet);
        if (decision.shouldInitiateContact) reachOutCount++;
      }
      // Should trigger most of the time (>70%)
      expect(reachOutCount, greaterThan(70));
    });

    test('loneliness 0.6 triggers reachOut only sometimes', () {
      final pet = _makePet(loneliness: 0.6);
      int reachOutCount = 0;
      for (int i = 0; i < 100; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(pet);
        if (decision.shouldInitiateContact) reachOutCount++;
      }
      // Should trigger sometimes (10-60%)
      expect(reachOutCount, greaterThan(5));
      expect(reachOutCount, lessThan(65));
    });

    test('loneliness 0.3 almost never triggers reachOut', () {
      final pet = _makePet(loneliness: 0.3);
      int reachOutCount = 0;
      for (int i = 0; i < 100; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(pet);
        if (decision.shouldInitiateContact) reachOutCount++;
      }
      // Should almost never trigger (<10%)
      expect(reachOutCount, lessThan(10));
    });

    test('extraverted pet reaches out more than introverted', () {
      final extraverted = _makePet(loneliness: 0.65, extraversion: 0.8);
      final introverted = _makePet(loneliness: 0.65, extraversion: 0.2);

      int extraCount = 0;
      int introCount = 0;
      for (int i = 0; i < 200; i++) {
        final d = BehaviorDecider(random: Random(i));
        if (d.evaluate(extraverted).shouldInitiateContact) extraCount++;
        if (d.evaluate(introverted).shouldInitiateContact) introCount++;
      }
      expect(extraCount, greaterThan(introCount));
    });
  });

  group('Probabilistic diary writing', () {
    test('high curiosity + arousal triggers diary sometimes', () {
      final pet = _makePet(curiosity: 0.8, arousal: 0.6);
      int diaryCount = 0;
      for (int i = 0; i < 100; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(pet);
        if (decision.actions.contains(PetAction.writeDiary)) diaryCount++;
      }
      // Should trigger sometimes but not always
      expect(diaryCount, greaterThan(20));
      expect(diaryCount, lessThan(90));
    });
  });

  // ════════════════════════════════════════════════════════
  // 确定性行为保持不变（safety-critical behaviors remain deterministic）
  // ════════════════════════════════════════════════════════

  group('Deterministic safety behaviors', () {
    test('withdraw is always deterministic (welfare mechanism)', () {
      final withdrawn = _makePet(valence: -0.8, arousal: 0.1, security: 0.1);
      for (int i = 0; i < 50; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(withdrawn);
        expect(decision.actions.contains(PetAction.withdraw), isTrue);
        expect(decision.conversationStyle, ConversationStyle.withdrawn);
      }
    });

    test('sleep at extreme fatigue is always deterministic', () {
      final exhausted = _makePet(fatigue: 0.95);
      for (int i = 0; i < 50; i++) {
        final decider = BehaviorDecider(random: Random(i));
        final decision = decider.evaluate(exhausted);
        expect(decision.actions.contains(PetAction.sleep), isTrue);
      }
    });
  });

  // ════════════════════════════════════════════════════════
  // 对话风格保持正确
  // ════════════════════════════════════════════════════════

  group('Conversation style backward compatibility', () {
    test('happy pet has happy style', () {
      final pet = _makePet(valence: 0.5, arousal: 0.3);
      final decider = BehaviorDecider(random: Random(42));
      expect(decider.evaluate(pet).conversationStyle, ConversationStyle.happy);
    });

    test('curious+energetic pet has curious style', () {
      final pet = _makePet(curiosity: 0.8, valence: 0.1, arousal: 0.6);
      final decider = BehaviorDecider(random: Random(42));
      expect(decider.evaluate(pet).conversationStyle, ConversationStyle.curious);
    });

    test('sad pet has melancholy style', () {
      final pet = _makePet(valence: -0.5, arousal: 0.3);
      final decider = BehaviorDecider(random: Random(42));
      expect(decider.evaluate(pet).conversationStyle, ConversationStyle.melancholy);
    });
  });
}
