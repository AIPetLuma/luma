import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/onboarding/ai_disclosure_screen.dart';
import 'package:luma/features/onboarding/birth_screen.dart';
import 'package:luma/features/onboarding/name_screen.dart';
import 'package:luma/features/home/home_screen.dart';
import 'package:luma/features/chat/chat_screen.dart';
import 'package:luma/features/settings/settings_screen.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/emotion.dart';
import 'package:luma/data/models/need.dart';

/// Integration tests for the end-to-end user flow:
///   Onboarding → Home → Chat → Settings
///
/// These tests verify screen transitions, data flow, and key user
/// interactions across the full app journey.
///
/// 集成测试覆盖完整用户路径：
///   引导页 → 首页 → 聊天页 → 设置页
///
/// 这些测试用于验证跨页面跳转、数据传递以及关键交互行为。

// ── Test helpers ──
// ── 测试辅助方法 ──

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
// ── 测试用例 ──

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  group('Full app flow: onboarding → home → chat → settings', () {
    testWidgets('complete onboarding flow', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Step 1: AI Disclosure screen
      // 步骤 1：AI 披露页面
      expect(find.textContaining('AI companion'), findsOneWidget);
      expect(find.textContaining('not a human'), findsOneWidget);
      expect(find.textContaining('988'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);

      // Accept disclosure
      // 同意披露并进入下一步
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      // Step 2: Birth screen (personality selection)
      // 步骤 2：性格选择页面
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Gentle Soul'), findsOneWidget);
      expect(find.text('Playful Spirit'), findsOneWidget);
      expect(find.text('Shy Dreamer'), findsOneWidget);

      // Select "Explorer" preset
      // 选择 “Explorer” 预设
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();

      // Continue button should be enabled, tap it
      // 继续按钮应可点击并进入命名页
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Name screen
      // 步骤 3：命名页面
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Bring to life'), findsOneWidget);

      // Enter name
      // 输入宠物名
      await tester.enterText(find.byType(TextField), 'Luna');
      await tester.pumpAndSettle();

      // Tap "Bring to life"
      // 点击创建按钮
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Step 4: Now on Home screen
      // 步骤 4：进入首页
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
    });

    testWidgets('home → chat → home transition', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      // 快速通过引导流程
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
      // 已在首页
      expect(find.text('Pixel'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);

      // Tap "Talk" to go to chat
      // 点击聊天进入 Chat 页
      await tester.tap(find.text('Talk'));
      await tester.pumpAndSettle();

      // Chat screen should show pet name and disclosure reminder
      // 聊天页应显示宠物名和披露提醒
      expect(find.text('Pixel'), findsOneWidget);
      expect(find.textContaining('Reminder'), findsOneWidget);
      expect(find.textContaining('AI companion'), findsOneWidget);

      // Empty chat state
      // 空会话态文案
      expect(find.textContaining('Say hello'), findsOneWidget);

      // Go back to home
      // 返回首页
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on home screen
      // 返回后仍为首页
      expect(find.text('Talk'), findsOneWidget);
      expect(find.text('Pixel'), findsOneWidget);
    });

    testWidgets('home → settings → home transition', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      // 快速通过引导流程
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Surprise me'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Surprise me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mochi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bring to life'));
      await tester.pumpAndSettle();

      // Tap settings icon
      // 点击设置图标
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Settings screen should show pet info
      // 设置页显示宠物信息
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Mochi'), findsOneWidget);
      expect(find.textContaining('Day'), findsWidgets);
      expect(find.text('Trust score'), findsOneWidget);

      // AI Disclosure section visible
      // AI 披露模块可见
      expect(find.text('AI Disclosure'), findsOneWidget);
      expect(find.textContaining('AI companion'), findsOneWidget);

      // Crisis resources visible
      // 危机资源模块可见
      await _scrollTo(tester, find.text('Crisis Text Line'));
      expect(find.textContaining('988'), findsWidgets);
      expect(find.text('Crisis Text Line'), findsOneWidget);

      // API key section visible
      // API Key 模块可见
      await _scrollTo(tester, find.text('LLM API key'));
      expect(find.text('LLM API key'), findsOneWidget);

      // Data & privacy section visible
      // 数据与隐私模块可见
      expect(find.textContaining('stays on your device'), findsOneWidget);

      // Reset pet button visible
      // 重置按钮可见
      expect(find.text('Reset pet'), findsOneWidget);

      // Go back to home
      // 返回首页
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on home
      // 回到首页后关键元素仍可见
      expect(find.text('Mochi'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
    });

    testWidgets('settings reset returns to onboarding', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward through onboarding
      // 快速通过引导流程
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
      // 进入设置页
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap "Reset pet"
      // 点击重置按钮
      await _scrollTo(tester, find.text('Reset pet'));
      await tester.tap(find.text('Reset pet'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      // 确认弹窗出现
      expect(find.text('Reset pet?'), findsOneWidget);
      expect(find.textContaining('permanently delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Confirm reset
      // 二次确认重置
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Should return to AI disclosure screen (onboarding start)
      // 应返回到 onboarding 起点（披露页）
      expect(find.textContaining('Before we begin'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
    });

    testWidgets('chat shows message input and send button', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward to chat
      // 快速进入聊天页
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
      // 聊天页已可见
      expect(find.text('Nova'), findsOneWidget);

      // Input bar with text field and send button
      // 输入栏包含文本框和发送按钮
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Type a message
      // 输入消息
      await tester.enterText(find.byType(TextField), 'Hello!');
      await tester.pumpAndSettle();

      // Send button should be available
      // 发送按钮保持可用
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('disclosure reminder shown in chat screen', (tester) async {
      await tester.pumpWidget(const _TestAppFlow());
      await tester.pumpAndSettle();

      // Fast-forward to chat
      // 快速进入聊天页
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
      // 披露提醒应可见（合规要求）
      expect(find.textContaining('Reminder'), findsOneWidget);
      expect(find.textContaining('AI companion, not a human'), findsOneWidget);

      // Dismiss button present
      // 提醒关闭按钮存在
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
      // 宠物名和天数可见
      expect(find.text('Echo'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);

      // Emotion label visible
      // 情绪标签可见
      expect(find.textContaining('Feeling'), findsOneWidget);

      // Talk and Diary buttons visible
      // Talk 与 Diary 按钮可见
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
      // 宠物信息模块
      expect(find.text('Star'), findsOneWidget);
      expect(find.text('Trust score'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // AI Disclosure (NY GBS Art. 47 compliance)
      // AI 披露模块（合规）
      expect(find.text('AI Disclosure'), findsOneWidget);
      expect(find.textContaining('not a human'), findsOneWidget);

      // Crisis resources (always accessible)
      // 危机资源（应始终可访问）
      await _scrollTo(tester, find.text('Crisis resources'));
      expect(find.text('Crisis resources'), findsOneWidget);
      expect(find.textContaining('988'), findsWidgets);
      expect(find.textContaining('741741'), findsOneWidget);

      // Data & privacy
      // 数据与隐私
      await _scrollTo(tester, find.text('Data & privacy'));
      expect(find.text('Data & privacy'), findsOneWidget);
      expect(find.textContaining('stays on your device'), findsOneWidget);

      // App version
      // 版本信息
      expect(find.text('Luma v0.1.0'), findsOneWidget);
    });
  });
}
