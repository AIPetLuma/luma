import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/onboarding/ai_disclosure_screen.dart';
import 'package:luma/features/onboarding/birth_screen.dart';
import 'package:luma/features/onboarding/name_screen.dart';
import 'package:luma/core/identity/pet_identity.dart';

// Test Scope (EN):
// - Validate onboarding compliance gate (AI disclosure).
// - Validate birth step interaction gating and preset selection behavior.
// - Validate naming step input validation and submit payload trimming.
//
// 测试范围（中文）：
// - 校验 onboarding 合规入口（AI 披露）是否可见且可确认。
// - 校验性格选择步骤的按钮门禁与选择逻辑。
// - 校验命名步骤输入校验与提交前 trim 行为。
void main() {
  group('AiDisclosureScreen', () {
    // EN: Legal disclosure must be visible before user proceeds.
    // 中文：用户继续前必须看到合规披露内容。
    testWidgets('displays required disclosure text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AiDisclosureScreen(onAccepted: () {}),
        ),
      );

      // Must contain AI identity disclosure.
      expect(find.textContaining('AI companion'), findsOneWidget);
      expect(find.textContaining('not a human'), findsOneWidget);
      // Must contain crisis info.
      expect(find.textContaining('988'), findsOneWidget);
      // Must have the accept button.
      expect(find.text('I understand'), findsOneWidget);
    });

    // EN: Confirm action should trigger acceptance callback.
    // 中文：确认按钮点击后应回调 onAccepted。
    testWidgets('calls onAccepted when button tapped', (tester) async {
      var accepted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AiDisclosureScreen(onAccepted: () => accepted = true),
        ),
      );

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
    });
  });

  group('BirthScreen', () {
    // EN: All preset options (and random option) should be discoverable.
    // 中文：所有预设与随机选项都应可见/可滚动到可见。
    testWidgets('shows all personality presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BirthScreen(onSelected: (_) {}),
        ),
      );

      for (final preset in PersonalityPreset.values) {
        expect(find.text(preset.label), findsOneWidget);
      }
      // Plus the "Surprise me" option.
      await tester.scrollUntilVisible(
        find.text('Surprise me'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Surprise me'), findsOneWidget);
    });

    // EN: Continue remains disabled until explicit choice is made.
    // 中文：未显式选择前，继续按钮应保持禁用。
    testWidgets('continue button disabled until selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BirthScreen(onSelected: (_) {}),
        ),
      );

      // Button should be disabled (no selection yet).
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    // EN: Choosing any preset should unlock continue action.
    // 中文：选择任一预设后，应解锁继续按钮。
    testWidgets('selecting a preset enables continue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BirthScreen(onSelected: (_) {}),
        ),
      );

      // Tap "Explorer".
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();

      // Button should now be enabled.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('NameScreen', () {
    // EN: Empty input should keep CTA disabled.
    // 中文：输入为空时，主按钮应禁用。
    testWidgets('button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameScreen(onNamed: (_) {}),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    // EN: Non-empty valid name should enable CTA.
    // 中文：输入合法非空名字后，主按钮应可用。
    testWidgets('button enabled when name is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameScreen(onNamed: (_) {}),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Luna');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    // EN: Submitted value should be trimmed before callback.
    // 中文：提交前应去除首尾空格，再回调上层。
    testWidgets('calls onNamed with trimmed text', (tester) async {
      String? name;
      await tester.pumpWidget(
        MaterialApp(
          home: NameScreen(onNamed: (n) => name = n),
        ),
      );

      await tester.enterText(find.byType(TextField), '  Luna  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      expect(name, 'Luna');
    });
  });
}
