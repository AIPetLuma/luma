import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/settings/settings_screen.dart';
import 'package:luma/data/models/pet_state.dart';
import 'package:luma/data/models/need.dart';
import 'package:luma/data/models/emotion.dart';

// Test Scope (EN):
// - Validate settings surface for identity, disclosure, and crisis resources.
// - Keep checks on user-visible compliance sections.
//
// 测试范围（中文）：
// - 校验设置页中的身份信息、披露信息与危机资源入口。
// - 聚焦用户可见合规模块，防止回归。
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
    // EN: pet identity and high-level stats should be visible.
    // 中文：宠物身份与核心统计信息应可见。
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

    // EN: AI disclosure section must remain discoverable.
    // 中文：AI 披露模块必须始终可被用户访问。
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

    // EN: crisis resources should be present, even if scrolled.
    // 中文：危机资源必须存在，必要时通过滚动定位。
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

      await tester.scrollUntilVisible(
        find.text('Crisis resources'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('988'), findsWidgets);
    });
  });
}
