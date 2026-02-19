import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/onboarding/ai_disclosure_screen.dart';
import 'package:luma/features/onboarding/birth_screen.dart';
import 'package:luma/features/onboarding/name_screen.dart';
import 'package:luma/features/home/home_screen.dart';
import 'package:luma/features/chat/chat_screen.dart';
import 'package:luma/features/settings/settings_screen.dart';
import 'package:luma/core/identity/pet_identity.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';

/// Integration tests for the end-to-end user flow:
///   Onboarding → Home → Chat → Settings
///
/// These tests verify screen transitions, data flow, and key user
/// interactions across the full app journey.

// ── Test helpers ──

PetState _makePet({String name = 'Luna'}) => PetState(
      id: 'test-pet-001',
      name: name,
      birthday: DateTime.now(),
      personality: {
        'openness': 0.8,
        'conscientiousness': 0.5,
        'extraversion': 0.6,
        'agreeableness': 0.5,
        'neuroticism': 0.3,
      },
      needs: Needs(),
      emotion: Emotion(valence: 0.4, arousal: 0.5),
      trustScore: 0.5,
      lastActiveAt: DateTime.now(),
      totalInteractions: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

/// Simulates the full AppRouter logic: starts at disclosure, walks through
/// the onboarding flow, then transitions to the main screens.
class _TestAppFlow extends StatefulWidget {
  const _TestAppFlow();

  @override
  State<_TestAppFlow> createState() => _TestAppFlowState();
}

class _TestAppFlowState extends State<_TestAppFlow> {
  _FlowStep _step = _FlowStep.disclosure;
  PersonalityPreset? _preset;
  PetState? _pet;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _FlowStep.disclosure:
        return AiDisclosureScreen(
          key: const ValueKey('disclosure'),
          onAccepted: () => setState(() => _step = _FlowStep.birth),
        );
      case _FlowStep.birth:
        return BirthScreen(
          key: const ValueKey('birth'),
          onSelected: (p) => setState(() {
            _preset = p;
            _step = _FlowStep.name;
          }),
        );
      case _FlowStep.name:
        return NameScreen(
          key: const ValueKey('name'),
          onNamed: (name) => setState(() {
            _pet = _makePet(name: name);
            _step = _FlowStep.home;
          }),
        );
      case _FlowStep.home:
        return HomeScreen(
          key: const ValueKey('home'),
          petState: _pet!,
          diaryEntries: const [],
          onChatTap: () => setState(() => _step = _FlowStep.chat),
          onSettingsTap: () => setState(() => _step = _FlowStep.settings),
        );
      case _FlowStep.chat:
        return ChatScreen(
          key: const ValueKey('chat'),
          petState: _pet!,
          messages: const [],
          showDisclosureReminder: true,
          onDisclosureDismissed: () {},
          onSendMessage: (text) async => const ChatResult(
            reply: '*purrs softly*',
            isCrisis: false,
            riskLevel: 0,
          ),
          onBack: () => setState(() => _step = _FlowStep.home),
        );
      case _FlowStep.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          petState: _pet!,
          onBack: () => setState(() => _step = _FlowStep.home),
          onResetPet: () => setState(() {
            _pet = null;
            _step = _FlowStep.disclosure;
          }),
          onApiKeyChanged: (_) {},
        );
    }
  }
}

enum _FlowStep { disclosure, birth, name, home, chat, settings }

// ── Tests ──

void main() {
  group('Full app flow: onboarding → home → chat → settings', () {
    testWidgets('complete onboarding flow', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Step 1: AI Disclosure screen
      expect(find.textContaining('AI companion'), findsOneWidget);
      expect(find.textContaining('not a human'), findsOneWidget);
      expect(find.textContaining('988'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);

      // Accept disclosure
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      // Step 2: Birth screen (personality selection)
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Gentle Soul'), findsOneWidget);
      expect(find.text('Playful Spirit'), findsOneWidget);
      expect(find.text('Shy Dreamer'), findsOneWidget);
      expect(find.text('Surprise me'), findsOneWidget);

      // Select "Explorer" preset
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();

      // Continue button should be enabled, tap it
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Name screen
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Bring to life'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField), 'Luna');
      await tester.pumpAndSettle();

      // Tap "Bring to life"
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Step 4: Now on Home screen
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
    });

    testWidgets('home → chat → home transition', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Pixel');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Now on Home screen
      expect(find.text('Pixel'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);

      // Tap "Talk" to go to chat
      await tester.tap(find.text('Talk'));
      await tester.pumpAndSettle();

      // Chat screen should show pet name and disclosure reminder
      expect(find.text('Pixel'), findsOneWidget);
      expect(find.textContaining('Reminder'), findsOneWidget);
      expect(find.textContaining('AI companion'), findsOneWidget);

      // Empty chat state
      expect(find.textContaining('Say hello'), findsOneWidget);

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on home screen
      expect(find.text('Talk'), findsOneWidget);
      expect(find.text('Pixel'), findsOneWidget);
    });

    testWidgets('home → settings → home transition', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Surprise me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mochi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Tap settings icon
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Settings screen should show pet info
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Mochi'), findsOneWidget);
      expect(find.textContaining('Day'), findsWidgets);
      expect(find.text('Trust score'), findsOneWidget);

      // AI Disclosure section visible
      expect(find.text('AI Disclosure'), findsOneWidget);
      expect(find.textContaining('AI companion'), findsOneWidget);

      // Crisis resources visible
      expect(find.textContaining('988'), findsOneWidget);
      expect(find.text('Crisis Text Line'), findsOneWidget);

      // API key section visible
      expect(find.text('Anthropic API key'), findsOneWidget);

      // Data & privacy section visible
      expect(find.textContaining('stays on your device'), findsOneWidget);

      // Reset pet button visible
      expect(find.text('Reset pet'), findsOneWidget);

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on home
      expect(find.text('Mochi'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
    });

    testWidgets('settings reset returns to onboarding', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Buddy');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap "Reset pet"
      await tester.tap(find.text('Reset pet'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Reset pet?'), findsOneWidget);
      expect(find.textContaining('permanently delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Confirm reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Should return to AI disclosure screen (onboarding start)
      expect(find.textContaining('Before we begin'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
    });

    testWidgets('chat shows message input and send button', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward to chat
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nova');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talk'));
      await tester.pumpAndSettle();

      // Chat screen is visible
      expect(find.text('Nova'), findsOneWidget);

      // Input bar with text field and send button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Type a message
      await tester.enterText(find.byType(TextField), 'Hello!');
      await tester.pumpAndSettle();

      // Send button should be available
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('disclosure reminder shown in chat screen', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward to chat
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gentle Soul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Willow');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talk'));
      await tester.pumpAndSettle();

      // Disclosure reminder is visible (compliance: NY GBS Art. 47)
      expect(find.textContaining('Reminder'), findsOneWidget);
      expect(find.textContaining('AI companion, not a human'), findsOneWidget);

      // Dismiss button present
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('home screen shows emotional state and needs', (tester) async {
      final pet = _makePet(name: 'Echo');
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            petState: pet,
            diaryEntries: const [],
            onChatTap: () {},
            onSettingsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pet name and day visible
      expect(find.text('Echo'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);

      // Emotion label visible
      expect(find.textContaining('Feeling'), findsOneWidget);

      // Talk and Diary buttons visible
      expect(find.text('Talk'), findsOneWidget);
      expect(find.textContaining('Diary'), findsOneWidget);
    });

    testWidgets('settings shows all required compliance sections',
        (tester) async {
      final pet = _makePet(name: 'Star');
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            petState: pet,
            onBack: () {},
            onResetPet: () {},
            onApiKeyChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pet info
      expect(find.text('Star'), findsOneWidget);
      expect(find.text('Trust score'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // AI Disclosure (NY GBS Art. 47 compliance)
      expect(find.text('AI Disclosure'), findsOneWidget);
      expect(find.textContaining('not a human'), findsOneWidget);

      // Crisis resources (always accessible)
      expect(find.text('Crisis resources'), findsOneWidget);
      expect(find.textContaining('988'), findsOneWidget);
      expect(find.textContaining('741741'), findsOneWidget);

      // Data & privacy
      expect(find.text('Data & privacy'), findsOneWidget);
      expect(find.textContaining('stays on your device'), findsOneWidget);

      // App version
      expect(find.text('Luma v0.1.0'), findsOneWidget);
    });
  });
}
