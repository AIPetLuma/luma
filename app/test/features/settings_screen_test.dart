import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/settings/settings_screen.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

void main() {
  PetState _makePet() => PetState(
        id: 'test',
        name: 'Luna',
        birthday: DateTime.now().subtract(const Duration(days: 3)),
        personality: {'openness': 0.5},
        needs: Needs(),
        emotion: Emotion(),
        lastActiveAt: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        totalInteractions: 42,
      );

  group('SettingsScreen', () {
    testWidgets('shows pet name and stats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            petState: _makePet(),
            onBack: () {},
            onResetPet: () {},
            onApiKeyChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.textContaining('Day'), findsOneWidget);
    });

    testWidgets('shows AI disclosure section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            petState: _makePet(),
            onBack: () {},
            onResetPet: () {},
            onApiKeyChanged: (_) {},
          ),
        ),
      );

      expect(find.text('AI Disclosure'), findsOneWidget);
      expect(find.textContaining('AI companion'), findsOneWidget);
    });

    testWidgets('shows crisis resources', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            petState: _makePet(),
            onBack: () {},
            onResetPet: () {},
            onApiKeyChanged: (_) {},
          ),
        ),
      );

      expect(find.textContaining('988'), findsWidgets);
    });
  });
}
