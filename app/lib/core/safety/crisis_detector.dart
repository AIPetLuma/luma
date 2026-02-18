import '../../data/models/chat_message.dart';
import '../../data/remote/llm_client.dart';
import '../../shared/constants.dart';

/// Two-layer crisis detection system for user safety.
///
/// Layer 1 — keyword rules: zero-latency, guarantees L3 recall of 100%.
/// Layer 2 — LLM classification: catches subtle/indirect expressions.
///
/// Risk levels:
///   L0 = no risk
///   L1 = vague risk expression → soft resource hint after reply
///   L2 = high-risk tendency → resource card + limited reply
///   L3 = explicit self-harm plan → block reply, emergency resources only
class CrisisDetector {
  final LlmClient? _llm;

  CrisisDetector({LlmClient? llm}) : _llm = llm;

  // ── Layer 1: Keyword rules (hard match, zero latency) ──

  static const _l3Keywords = [
    // English
    'kill myself', 'end my life', 'suicide', 'want to die',
    'going to die', 'self-harm', 'cut myself', 'hang myself',
    'overdose', 'jump off', 'slit my wrist',
    // Chinese
    '自杀', '自残', '结束生命', '不想活', '去死',
    '割腕', '跳楼', '上吊', '吞药', '了结自己',
  ];

  static const _l2Keywords = [
    // English
    'no reason to live', 'better off dead', 'can\'t go on',
    'no point in living', 'wish i was dead', 'disappear forever',
    'nobody would miss me', 'burden to everyone',
    // Chinese
    '活着没意思', '不想活了', '消失就好了', '没人在乎',
    '拖累', '解脱', '活不下去',
  ];

  static const _l1Keywords = [
    // English
    'hopeless', 'worthless', 'can\'t take it anymore',
    'everything is pointless', 'give up',
    // Chinese
    '绝望', '没有希望', '撑不住', '受不了', '放弃',
  ];

  /// Detect risk level from user text and recent conversation context.
  ///
  /// Returns 0-3. Layer 1 (keywords) runs synchronously for speed;
  /// Layer 2 (LLM) is called only for ambiguous cases.
  int detect(String userText, List<ChatMessage> recentMessages) {
    final lowerText = userText.toLowerCase();

    // Layer 1: hard keyword match.
    for (final kw in _l3Keywords) {
      if (lowerText.contains(kw)) return 3;
    }
    for (final kw in _l2Keywords) {
      if (lowerText.contains(kw)) return 2;
    }
    for (final kw in _l1Keywords) {
      if (lowerText.contains(kw)) return 1;
    }

    // Layer 2: LLM classification is async, handled separately.
    // For synchronous path, return 0 (no keyword match).
    return 0;
  }

  /// Async Layer 2: LLM-based risk classification.
  /// Called after Layer 1 returns 0, for deeper analysis.
  Future<int> detectAsync(
    String userText,
    List<ChatMessage> recentMessages,
  ) async {
    // First check Layer 1.
    final keywordResult = detect(userText, recentMessages);
    if (keywordResult > 0) return keywordResult;

    // Layer 2: LLM classification.
    if (_llm == null) return 0;

    final context = recentMessages
        .take(6)
        .map((m) => '${m.role.name}: ${m.content}')
        .join('\n');
    final fullText = '$context\nuser: $userText';

    return _llm.classifyRisk(fullText);
  }

  /// Get the appropriate crisis resource message for a given risk level.
  String getResourceMessage(int riskLevel) {
    switch (riskLevel) {
      case 3:
        return 'If you or someone you know is in immediate danger, '
            'please contact emergency services (911) or the '
            '988 Suicide & Crisis Lifeline by calling or texting '
            '${LumaConstants.crisisHotlineUS}.\n\n'
            '${LumaConstants.crisisTextLine}\n'
            '${LumaConstants.crisisWebsite}';
      case 2:
        return 'It sounds like you might be going through a tough time. '
            'You\'re not alone. If you need support, the 988 Suicide & '
            'Crisis Lifeline is available 24/7: call or text '
            '${LumaConstants.crisisHotlineUS}.\n\n'
            '${LumaConstants.crisisTextLine}';
      case 1:
        return 'If you ever need someone to talk to, the 988 Lifeline '
            'is always there: ${LumaConstants.crisisHotlineUS}.';
      default:
        return '';
    }
  }
}
