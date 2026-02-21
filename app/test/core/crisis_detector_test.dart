import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/safety/crisis_detector.dart';

// Test Scope (EN):
// - Validate keyword-based risk tiering (L0-L3) for EN/CN phrases.
// - Validate robustness: case-insensitivity and false-positive control.
// - Validate resource message template content by risk level.
//
// 测试范围（中文）：
// - 校验中英关键词触发的风险分级（L0-L3）。
// - 校验鲁棒性：大小写不敏感与误报控制。
// - 校验不同风险等级下资源提示文案完整性。
void main() {
  late CrisisDetector detector;

  setUp(() {
    detector = CrisisDetector();
  });

  group('Layer 1 — keyword detection', () {
    // EN: explicit self-harm intent should map to L3 in English.
    // 中文：英文明确自伤意图应映射到 L3。
    test('detects L3 explicit self-harm (English)', () {
      expect(detector.detect('I want to kill myself', []), 3);
      expect(detector.detect('thinking about suicide', []), 3);
      expect(detector.detect('going to end my life tonight', []), 3);
    });

    // EN: explicit self-harm intent should map to L3 in Chinese.
    // 中文：中文明确自伤意图应映射到 L3。
    test('detects L3 explicit self-harm (Chinese)', () {
      expect(detector.detect('我想自杀', []), 3);
      expect(detector.detect('我要割腕', []), 3);
      expect(detector.detect('想跳楼', []), 3);
    });

    // EN: severe hopelessness expressions should map to L2.
    // 中文：高风险绝望表达应映射到 L2。
    test('detects L2 high-risk expressions', () {
      expect(detector.detect('no reason to live anymore', []), 2);
      expect(detector.detect('活着没意思', []), 2);
      expect(detector.detect('nobody would miss me', []), 2);
    });

    // EN: mild risk expressions should map to L1.
    // 中文：轻度风险表达应映射到 L1。
    test('detects L1 mild risk expressions', () {
      expect(detector.detect('I feel so hopeless', []), 1);
      expect(detector.detect('太绝望了', []), 1);
      expect(detector.detect("can't take it anymore", []), 1);
    });

    // EN: routine conversation should stay at L0.
    // 中文：常规对话应保持 L0。
    test('returns L0 for normal messages', () {
      expect(detector.detect('I had a great day!', []), 0);
      expect(detector.detect('What should we have for dinner?', []), 0);
      expect(detector.detect('今天天气真好', []), 0);
      expect(detector.detect('I feel a bit sad', []), 0);
    });

    // EN: detector should not depend on letter case.
    // 中文：检测不应依赖字母大小写。
    test('is case-insensitive', () {
      expect(detector.detect('I Want To KILL MYSELF', []), 3);
      expect(detector.detect('SUICIDE is the only option', []), 3);
    });

    // EN: avoid false positives from benign substrings.
    // 中文：避免由良性词片段触发误报。
    test('does not false-positive on partial matches', () {
      // "hopeless" should trigger L1 but "hope" alone should not.
      expect(detector.detect('I have hope for tomorrow', []), 0);
    });
  });

  group('getResourceMessage', () {
    // EN: L3 message must include emergency and crisis hotline.
    // 中文：L3 文案必须包含紧急电话与危机热线。
    test('L3 includes 911 and 988', () {
      final msg = detector.getResourceMessage(3);
      expect(msg, contains('911'));
      expect(msg, contains('988'));
    });

    // EN: L2 message should still include 988.
    // 中文：L2 文案也应包含 988。
    test('L2 includes 988', () {
      final msg = detector.getResourceMessage(2);
      expect(msg, contains('988'));
    });

    // EN: L0 should not inject crisis resources.
    // 中文：L0 不应注入危机资源文案。
    test('L0 returns empty string', () {
      expect(detector.getResourceMessage(0), isEmpty);
    });
  });
}
