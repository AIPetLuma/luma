import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/engine/goal_system.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

void main() {
  late GoalSystem system;

  setUp(() {
    system = GoalSystem();
  });

  // ════════════════════════════════════════════════════════
  // 目标生成
  // ════════════════════════════════════════════════════════

  group('Goal generation', () {
    test('high loneliness generates a social goal', () {
      final needs = Needs(loneliness: 0.8, curiosity: 0.3);
      final emotion = Emotion(valence: -0.1, arousal: 0.3);
      final personality = {'extraversion': 0.6, 'openness': 0.5};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      expect(goals, isNotEmpty);
      expect(
        goals.any((g) => g.type == GoalType.social),
        isTrue,
        reason: 'Lonely pet should generate social goal',
      );
    });

    test('high curiosity generates an exploration goal', () {
      final needs = Needs(loneliness: 0.3, curiosity: 0.85);
      final emotion = Emotion(valence: 0.2, arousal: 0.5);
      final personality = {'openness': 0.8, 'extraversion': 0.5};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      expect(goals.any((g) => g.type == GoalType.exploration), isTrue);
    });

    test('exhausted pet does not generate active goals', () {
      final needs = Needs(fatigue: 0.95, curiosity: 0.8);
      final emotion = Emotion(valence: -0.2, arousal: 0.1);
      final personality = {'openness': 0.8, 'extraversion': 0.8};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      // Should only have rest goal or no goals
      expect(
        goals.every((g) => g.type == GoalType.rest || g.type == GoalType.comfort),
        isTrue,
      );
    });

    test('no duplicate goal types generated', () {
      final needs = Needs(loneliness: 0.9, curiosity: 0.9);
      final emotion = Emotion(valence: 0.3, arousal: 0.6);
      final personality = {'openness': 0.8, 'extraversion': 0.8};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      final types = goals.map((g) => g.type).toSet();
      expect(types.length, equals(goals.length));
    });
  });

  // ════════════════════════════════════════════════════════
  // 目标进度与完成
  // ════════════════════════════════════════════════════════

  group('Goal progress and completion', () {
    test('chat interaction advances social goal', () {
      final goal = Goal(
        type: GoalType.social,
        description: 'Chat with owner',
        progress: 0.0,
        priority: 0.8,
      );

      final updated = system.advanceGoal(goal, GoalEvent.chatReceived);
      expect(updated.progress, greaterThan(0.0));
    });

    test('goal completes at progress 1.0', () {
      final goal = Goal(
        type: GoalType.social,
        description: 'Chat with owner',
        progress: 0.9,
        priority: 0.8,
      );

      final updated = system.advanceGoal(goal, GoalEvent.chatReceived);
      expect(updated.isComplete, isTrue);
    });

    test('completed goal produces positive emotion delta', () {
      final goal = Goal(
        type: GoalType.social,
        description: 'Chat with owner',
        progress: 1.0,
        priority: 0.8,
      );

      final delta = system.emotionDeltaForCompletion(goal);
      expect(delta.valence, greaterThan(0));
    });

    test('failed goal produces negative emotion delta', () {
      final goal = Goal(
        type: GoalType.social,
        description: 'Chat with owner',
        progress: 0.2,
        priority: 0.8,
      );

      final delta = system.emotionDeltaForFailure(goal);
      expect(delta.valence, lessThan(0));
    });
  });

  // ════════════════════════════════════════════════════════
  // 目标限制
  // ════════════════════════════════════════════════════════

  group('Goal constraints', () {
    test('maximum active goals is limited', () {
      final needs = Needs(loneliness: 0.9, curiosity: 0.9, security: 0.1);
      final emotion = Emotion(valence: 0.0, arousal: 0.8);
      final personality = {'openness': 0.9, 'extraversion': 0.9};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      expect(goals.length, lessThanOrEqualTo(3));
    });

    test('goals have descriptions', () {
      final needs = Needs(loneliness: 0.8);
      final emotion = Emotion(valence: 0.0, arousal: 0.3);
      final personality = {'extraversion': 0.5, 'openness': 0.5};

      final goals = system.generateGoals(
        needs: needs,
        emotion: emotion,
        personality: personality,
      );

      for (final goal in goals) {
        expect(goal.description, isNotEmpty);
        expect(goal.priority, greaterThan(0.0));
        expect(goal.priority, lessThanOrEqualTo(1.0));
      }
    });
  });
}
