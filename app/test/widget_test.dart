import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luma/app.dart';

// Test Scope (EN):
// - Boot smoke test for root app wiring (ProviderScope + MaterialApp tree).
// - Validate first user-facing phase is reachable (loading/disclosure).
//
// 测试范围（中文）：
// - 根应用接线冒烟测试（ProviderScope + MaterialApp 树）。
// - 校验首个用户可见阶段可到达（加载页/披露页）。
void main() {
  testWidgets('LumaApp boot route smoke test', (WidgetTester tester) async {
    // EN: Start the full app tree as production entry would do.
    // 中文：按生产入口方式启动完整应用树。
    await tester.pumpWidget(const ProviderScope(child: LumaApp()));
    await tester.pump(const Duration(milliseconds: 300));

    // EN: Root app should be mounted and build a Material shell.
    // 中文：根组件应挂载成功，并构建 Material 外壳。
    expect(find.byType(LumaApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);

    // EN: App should show an initial user-visible phase.
    // 中文：应用应展示一个可见的初始阶段（加载或入门披露）。
    final loadingVisible = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.textContaining('waking up').evaluate().isNotEmpty;
    final disclosureVisible = find.textContaining('Before we begin').evaluate().isNotEmpty ||
        find.text('I understand').evaluate().isNotEmpty;
    expect(loadingVisible || disclosureVisible, isTrue);
  });
}
