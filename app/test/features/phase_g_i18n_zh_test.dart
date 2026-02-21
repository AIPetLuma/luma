import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/identity/pet_identity.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/features/chat/chat_screen.dart';
import 'package:luma/features/onboarding/birth_screen.dart';
import 'package:luma/features/onboarding/name_screen.dart';
import 'package:luma/features/settings/settings_screen.dart';
import 'package:luma/shared/l10n.dart';

// Test Scope (EN):
// - Verify Phase G zh locale wiring for onboarding/chat/settings.
// - Ensure key user-facing strings switch from default EN to zh.
//
// 测试范围（中文）：
// - 验证 Phase G 在中文 locale 下的 onboarding/chat/settings 文案接线。
// - 确保关键用户文案能从默认英文切换到中文。
Widget _wrapZh(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
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

PetState _pet({String name = '月光'}) {
  // EN: factory for deterministic zh-locale widget tests.
  // 中文：用于中文场景测试的稳定 PetState 构造器。
  final now = DateTime.now();
  return PetState(
    id: 'pet-zh-1',
    name: name,
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
  group('Phase G zh locale coverage', () {
    // EN: birth step should render zh title/options/actions.
    // 中文：出生步骤应展示中文标题/选项/动作文案。
    testWidgets('BirthScreen renders Chinese copy', (tester) async {
      await tester.pumpWidget(_wrapZh(BirthScreen(onSelected: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('选择性格'), findsOneWidget);
      expect(find.text('探索者'), findsOneWidget);
      expect(find.text('继续'), findsOneWidget);
    });

    // EN: naming step should render zh title/CTA/hint.
    // 中文：命名步骤应展示中文标题/按钮/输入提示。
    testWidgets('NameScreen renders Chinese copy', (tester) async {
      await tester.pumpWidget(_wrapZh(NameScreen(onNamed: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('给你的 Luma 取名'), findsOneWidget);
      expect(find.text('赋予生命'), findsOneWidget);
      expect(find.textContaining('输入名字'), findsOneWidget);
    });

    // EN: chat empty-state/input/disclosure should be localized in zh.
    // 中文：聊天空态/输入框/披露提醒需中文化。
    testWidgets('ChatScreen empty state/input render Chinese copy',
        (tester) async {
      await tester.pumpWidget(
        _wrapZh(
          ChatScreen(
            petState: _pet(),
            messages: const [],
            showDisclosureReminder: true,
            onSendMessage: (_) async => const ChatResult(
              reply: 'hi',
              isCrisis: false,
              riskLevel: 0,
            ),
            onDisclosureDismissed: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('打个招呼'), findsOneWidget);
      expect(find.textContaining('输入消息'), findsOneWidget);
      expect(find.textContaining('提醒：Luma 是 AI 伙伴'), findsOneWidget);
    });

    // EN: settings section labels should switch to zh.
    // 中文：设置页核心模块标题需切换为中文。
    testWidgets('SettingsScreen renders Chinese copy', (tester) async {
      await tester.pumpWidget(
        _wrapZh(
          SettingsScreen(
            petState: _pet(),
            onBack: () {},
            onResetPet: () {},
            onApiKeyChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('你的 Luma'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('重置宠物'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('重置宠物'), findsOneWidget);
      expect(find.text('数据与隐私'), findsOneWidget);
    });
  });
}
