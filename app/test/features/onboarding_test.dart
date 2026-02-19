import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/onboarding/ai_disclosure_screen.dart';
import 'package:luma/features/onboarding/birth_screen.dart';
import 'package:luma/features/onboarding/name_screen.dart';
import 'package:luma/core/identity/pet_identity.dart';

void main() {
  group('AiDisclosureScreen', () {
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
      expect(find.text('Surprise me'), findsOneWidget);
    });

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

    testWidgets('selecting a preset enables continue', (tester) async {
      PersonalityPreset? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: BirthScreen(onSelected: (p) => selected = p),
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
    testWidgets('button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NameScreen(onNamed: (_) {}),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

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
