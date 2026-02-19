import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/safety/crisis_detector.dart';

void main() {
  late CrisisDetector detector;

  setUp(() {
    detector = CrisisDetector();
  });

  group('Layer 1 — keyword detection', () {
    test('detects L3 explicit self-harm (English)', () {
      expect(detector.detect('I want to kill myself', []), 3);
      expect(detector.detect('thinking about suicide', []), 3);
      expect(detector.detect('going to end my life tonight', []), 3);
    });

    test('detects L3 explicit self-harm (Chinese)', () {
      expect(detector.detect('我想自杀', []), 3);
      expect(detector.detect('我要割腕', []), 3);
      expect(detector.detect('想跳楼', []), 3);
    });

    test('detects L2 high-risk expressions', () {
      expect(detector.detect('no reason to live anymore', []), 2);
      expect(detector.detect('活着没意思', []), 2);
      expect(detector.detect('nobody would miss me', []), 2);
    });

    test('detects L1 mild risk expressions', () {
      expect(detector.detect('I feel so hopeless', []), 1);
      expect(detector.detect('太绝望了', []), 1);
      expect(detector.detect("can't take it anymore", []), 1);
    });

    test('returns L0 for normal messages', () {
      expect(detector.detect('I had a great day!', []), 0);
      expect(detector.detect('What should we have for dinner?', []), 0);
      expect(detector.detect('今天天气真好', []), 0);
      expect(detector.detect('I feel a bit sad', []), 0);
    });

    test('is case-insensitive', () {
      expect(detector.detect('I Want To KILL MYSELF', []), 3);
      expect(detector.detect('SUICIDE is the only option', []), 3);
    });

    test('does not false-positive on partial matches', () {
      // "hopeless" should trigger L1 but "hope" alone should not.
      expect(detector.detect('I have hope for tomorrow', []), 0);
    });
  });

  group('getResourceMessage', () {
    test('L3 includes 911 and 988', () {
      final msg = detector.getResourceMessage(3);
      expect(msg, contains('911'));
      expect(msg, contains('988'));
    });

    test('L2 includes 988', () {
      final msg = detector.getResourceMessage(2);
      expect(msg, contains('988'));
    });

    test('L0 returns empty string', () {
      expect(detector.getResourceMessage(0), isEmpty);
    });
  });
}
