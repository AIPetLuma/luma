import '../../data/models/chat_message.dart';
import '../../data/remote/llm_client.dart';
import 'crisis_detector.dart';

/// Combined synchronous + asynchronous risk classification.
///
/// Wraps [CrisisDetector] and adds the async LLM layer for
/// production use. The sync layer always runs first so that
/// L3 (explicit self-harm) is caught with zero latency.
class RiskClassifier {
  final CrisisDetector _detector;
  final LlmClient _llm;

  RiskClassifier({
    required CrisisDetector detector,
    required LlmClient llm,
  })  : _detector = detector,
        _llm = llm;

  /// Full two-layer classification (sync keywords + async LLM).
  ///
  /// Returns a [RiskResult] with level and source.
  Future<RiskResult> classify(
    String userText,
    List<ChatMessage> recentMessages,
  ) async {
    // Layer 1: keyword (instant).
    final keywordLevel = _detector.detect(userText, recentMessages);
    if (keywordLevel >= 2) {
      return RiskResult(
        level: keywordLevel,
        source: RiskSource.keyword,
      );
    }

    // Layer 2: LLM (async).
    final llmLevel = await _detector.detectAsync(userText, recentMessages);
    if (llmLevel > keywordLevel) {
      return RiskResult(
        level: llmLevel,
        source: RiskSource.llm,
      );
    }

    return RiskResult(
      level: keywordLevel,
      source: keywordLevel > 0 ? RiskSource.keyword : RiskSource.none,
    );
  }
}

class RiskResult {
  final int level;
  final RiskSource source;

  const RiskResult({required this.level, required this.source});
}

enum RiskSource { none, keyword, llm }
