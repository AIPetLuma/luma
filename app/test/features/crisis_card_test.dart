import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/chat/crisis_card.dart';

void main() {
  group('CrisisCard', () {
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
