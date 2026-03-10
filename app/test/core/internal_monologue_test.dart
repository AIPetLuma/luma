import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/internal_monologue.dart';
import 'package:luma/core/engine/goal_system.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

void main() {
  late InternalMonologue monologue;

  setUp(() {
    monologue = InternalMonologue();
  });

  // ════════════════════════════════════════════════════════
  // 内心想法生成
  // ════════════════════════════════════════════════════════

  group('Thought generation', () {
    test('generates a thought from needs and emotion', () {
      final needs = Needs(loneliness: 0.7, curiosity: 0.5);
      final emotion = Emotion(valence: -0.1, arousal: 0.3);

      final thought = monologue.generate(
        needs: needs,
        emotion: emotion,
        goals: [],
      );

      expect(thought, isNotNull);
      expect(thought.content, isNotEmpty);
      expect(thought.trigger, isNotNull);
    });

    test('lonely pet thinks about owner', () {
      final needs = Needs(loneliness: 0.9);
      final emotion = Emotion(valence: -0.2, arousal: 0.3);

      final thought = monologue.generate(
        needs: needs,
        emotion: emotion,
        goals: [],
      );

      expect(thought.trigger, ThoughtTrigger.loneliness);
    });

    test('curious pet thinks about exploration', () {
      final needs = Needs(loneliness: 0.2, curiosity: 0.9);
      final emotion = Emotion(valence: 0.3, arousal: 0.6);

      final thought = monologue.generate(
        needs: needs,
        emotion: emotion,
        goals: [],
      );

      expect(thought.trigger, ThoughtTrigger.curiosity);
    });

    test('tired pet thinks about rest', () {
      final needs = Needs(fatigue: 0.9, loneliness: 0.3);
      final emotion = Emotion(valence: -0.1, arousal: 0.1);

      final thought = monologue.generate(
        needs: needs,
        emotion: emotion,
        goals: [],
      );

      expect(thought.trigger, ThoughtTrigger.fatigue);
    });

    test('thought with active goal references the goal', () {
      final needs = Needs(loneliness: 0.5, curiosity: 0.7);
      final emotion = Emotion(valence: 0.2, arousal: 0.5);
      final goals = [
        const Goal(
          type: GoalType.exploration,
          description: 'Learn about the stars',
          progress: 0.3,
          priority: 0.7,
        ),
      ];

      final thought = monologue.generate(
        needs: needs,
        emotion: emotion,
        goals: goals,
      );

      expect(thought.trigger, ThoughtTrigger.goal);
    });
  });

  // ════════════════════════════════════════════════════════
  // 想法属性
  // ════════════════════════════════════════════════════════

  group('Thought properties', () {
    test('shareability varies by thought type', () {
      final lonely = monologue.generate(
        needs: Needs(loneliness: 0.9),
        emotion: Emotion(valence: -0.3, arousal: 0.2),
        goals: [],
      );

      final curious = monologue.generate(
        needs: Needs(curiosity: 0.9, loneliness: 0.1),
        emotion: Emotion(valence: 0.3, arousal: 0.6),
        goals: [],
      );

      // Lonely thoughts are more private (lower shareability)
      expect(lonely.shareability, lessThan(curious.shareability));
    });

    test('emotional weight reflects need intensity', () {
      final intense = monologue.generate(
        needs: Needs(loneliness: 0.95),
        emotion: Emotion(valence: -0.5, arousal: 0.4),
        goals: [],
      );

      final mild = monologue.generate(
        needs: Needs(loneliness: 0.55),
        emotion: Emotion(valence: 0.0, arousal: 0.3),
        goals: [],
      );

      expect(intense.emotionalWeight, greaterThan(mild.emotionalWeight));
    });
  });

  // ════════════════════════════════════════════════════════
  // Prompt 注入格式
  // ════════════════════════════════════════════════════════

  group('Prompt injection format', () {
    test('toPromptFragment returns non-empty string', () {
      final thought = monologue.generate(
        needs: Needs(loneliness: 0.7),
        emotion: Emotion(valence: -0.2, arousal: 0.3),
        goals: [],
      );

      final fragment = thought.toPromptFragment();
      expect(fragment, isNotEmpty);
      // Should be written from the pet's internal perspective
      expect(fragment.contains('think') || fragment.contains('feel') ||
             fragment.contains('wonder') || fragment.contains('wish') ||
             fragment.contains('miss'),
             isTrue);
    });
  });
}
