import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/identity/pet_identity.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/features/chat/chat_controller.dart' show kChatWarningLlmTimeout;
import 'package:luma/features/chat/chat_screen.dart';
import 'package:luma/shared/l10n.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    supportedLocales: L10n.supportedLocales,
    localizationsDelegates: const [
      L10nDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

PetState _pet() {
  final now = DateTime.now();
  return PetState(
    id: 'pet-warning-1',
    name: 'Sisi',
    birthday: now.subtract(const Duration(days: 2)),
    personality: PersonalityPreset.curious.traits,
    needs: Needs(),
    emotion: Emotion(valence: 0.3, arousal: 0.4),
    trustScore: 0.5,
    lastActiveAt: now,
    totalInteractions: 3,
    createdAt: now.subtract(const Duration(days: 2)),
    updatedAt: now,
  );
}

void main() {
  testWidgets('shows HTTP status warning when backend returns 4xx/5xx', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatScreen(
          petState: _pet(),
          messages: const [],
          showDisclosureReminder: false,
          onSendMessage: (_) async => const ChatResult(
            reply: '',
            isCrisis: false,
            riskLevel: 0,
            warningCode: 'http_error_400',
          ),
          onDisclosureDismissed: () {},
          onBack: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat_input_field')), 'hi');
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('HTTP 400'), findsOneWidget);
  });

  testWidgets('shows runtime reason warning when network times out', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatScreen(
          petState: _pet(),
          messages: const [],
          showDisclosureReminder: false,
          onSendMessage: (_) async => const ChatResult(
            reply: '',
            isCrisis: false,
            riskLevel: 0,
            warningCode: kChatWarningLlmTimeout,
          ),
          onDisclosureDismissed: () {},
          onBack: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat_input_field')), 'hello');
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('timed out'), findsOneWidget);
  });
}
