import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/chat/crisis_card.dart';

// Test Scope (EN):
// - Validate CrisisCard visual/text behavior by risk level.
// - Ensure emergency actions (Call/Text 988) are exposed for high risk.
//
// 测试范围（中文）：
// - 验证 CrisisCard 在不同风险等级下的文本与样式语义。
// - 验证高风险场景必须提供 988 呼叫/短信动作入口。
void main() {
  group('CrisisCard', () {
    // EN: L3 should render emergency-focused affordance.
    // 中文：L3 需要展示紧急干预语义与操作。
    testWidgets('L3 shows emergency styling and 988', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrisisCard(
              riskLevel: 3,
              message: 'Please contact 988 immediately.',
            ),
          ),
        ),
      );

      expect(find.text('Crisis Support'), findsOneWidget);
      expect(find.textContaining('988'), findsWidgets);
      expect(find.text('Call 988'), findsOneWidget);
      expect(find.text('Text 988'), findsOneWidget);
    });

    // EN: L2 should keep supportive tone while still exposing resources.
    // 中文：L2 应保持支持性语气，同时保留求助资源。
    testWidgets('L2 shows supportive styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrisisCard(
              riskLevel: 2,
              message: 'You are not alone in this.',
            ),
          ),
        ),
      );

      expect(find.text('You are not alone'), findsOneWidget);
      expect(find.textContaining('988'), findsWidgets);
    });

    // EN: L1 remains non-emergency but should keep reassurance.
    // 中文：L1 非紧急级别，但应保留安抚提示。
    testWidgets('L1 shows soft hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrisisCard(
              riskLevel: 1,
              message: 'The 988 Lifeline is always there.',
            ),
          ),
        ),
      );

      expect(find.text('You are not alone'), findsOneWidget);
    });
  });
}
