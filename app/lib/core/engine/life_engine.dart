import 'dart:async';
import '../../data/local/pet_dao.dart';
import '../../data/local/chat_dao.dart';
import '../../data/models/pet_state.dart';
import '../../shared/constants.dart';
import 'need_system.dart';
import 'emotion_system.dart';
import 'behavior_decider.dart';
import 'time_simulator.dart';

/// The beating heart of Luma — the `live()` loop.
///
/// This engine ticks every 60 seconds while the app is in foreground,
/// updating needs, emotions, and behaviour decisions. When the app
/// resumes from background, it fast-forwards through elapsed time
/// using [TimeSimulator].
///
/// Corresponds to the `live()` method in the design pseudocode
/// (see Appendix C of Luma_AI宠物创业报告_更新版.md).
class LifeEngine {
  final NeedSystem needSystem;
  final EmotionSystem emotionSystem;
  final BehaviorDecider behaviorDecider;
  final TimeSimulator timeSimulator;
  final PetDao _petDao;
  final ChatDao _chatDao;

  Timer? _tickTimer;
  PetState? _state;
  BehaviorDecision? _lastDecision;

  /// Whether the user is currently on the chat screen (affects need drift).
  bool isUserInteracting = false;

  /// Callback invoked when the pet wants to reach out (push notification).
  void Function(PetState state)? onReachOut;

  /// Callback invoked after each tick with the latest state.
  void Function(PetState state, BehaviorDecision decision)? onStateChanged;

  LifeEngine({
    NeedSystem? needSystem,
    EmotionSystem? emotionSystem,
    BehaviorDecider? behaviorDecider,
    TimeSimulator? timeSimulator,
    PetDao? petDao,
    ChatDao? chatDao,
  })  : needSystem = needSystem ?? NeedSystem(),
        emotionSystem = emotionSystem ?? EmotionSystem(),
        behaviorDecider = behaviorDecider ?? BehaviorDecider(),
        timeSimulator = timeSimulator ?? TimeSimulator(),
        _petDao = petDao ?? PetDao(),
        _chatDao = chatDao ?? ChatDao();

  PetState? get state => _state;
  BehaviorDecision? get lastDecision => _lastDecision;

  // ── Lifecycle ──

  /// Initialise the engine: load pet from DB, simulate offline time, start tick.
  Future<SimulationResult?> start() async {
    _state = await _petDao.load();
    if (_state == null) return null; // No pet yet — show onboarding.

    // Fast-forward through offline time.
    final elapsed = _state!.minutesSinceLastActive;
    SimulationResult? result;

    if (elapsed > 1) {
      result = timeSimulator.simulate(_state!, elapsed);
      _state = result.state;

      // Persist diary entries.
      for (final entry in result.diaryEntries) {
        await _chatDao.insertDiaryEntry(entry);
      }

      // Apply reunion emotion event.
      _state!.emotion = emotionSystem.onEvent(
        _state!.emotion,
        EmotionEvent.userReturned,
      );
    }

    // Persist updated state.
    await _petDao.update(_state!);

    // Start the foreground tick loop.
    _startTicking();

    return result;
  }

  /// Stop the tick loop (e.g. app going to background).
  void pause() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (_state != null) {
      _state!.lastActiveAt = DateTime.now();
      _petDao.update(_state!);
    }
  }

  /// Resume after returning to foreground.
  Future<SimulationResult?> resume() async {
    pause();
    return start();
  }

  void dispose() {
    pause();
  }

  // ── Tick ──

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(seconds: LumaConstants.tickIntervalSeconds),
      (_) => _tick(),
    );
  }

  Future<void> _tick() async {
    if (_state == null) return;

    // 1. Advance needs.
    _state!.needs = needSystem.tick(
      _state!.needs,
      1.0, // 1 minute per tick
      isInteracting: isUserInteracting,
    );

    // 2. Advance emotions.
    _state!.emotion = emotionSystem.tick(
      _state!.emotion,
      _state!.needs,
      1.0,
    );

    // 3. Evaluate behaviour.
    _lastDecision = behaviorDecider.evaluate(_state!);

    // 4. Execute actions.
    if (_lastDecision!.shouldInitiateContact) {
      onReachOut?.call(_state!);
    }

    // 5. Persist.
    _state!.lastActiveAt = DateTime.now();
    await _petDao.update(_state!);

    // 6. Notify listeners.
    onStateChanged?.call(_state!, _lastDecision!);
  }

  // ── Interaction hooks (called by ChatController) ──

  /// Call when the user sends a message.
  void onUserInteraction(InteractionType type) {
    if (_state == null) return;

    _state!.needs = needSystem.onInteraction(
      _state!.needs,
      type: type,
    );
    _state!.totalInteractions++;

    // Determine emotion event from interaction type.
    final emotionEvent = switch (type) {
      InteractionType.chat => EmotionEvent.positiveChat,
      InteractionType.newTopic => EmotionEvent.newTopicShared,
      InteractionType.positiveGesture => EmotionEvent.positiveChat,
      InteractionType.negativeGesture => EmotionEvent.negativeChat,
      InteractionType.sleep => EmotionEvent.longSilence,
    };
    _state!.emotion = emotionSystem.onEvent(_state!.emotion, emotionEvent);

    // Re-evaluate behaviour after interaction.
    _lastDecision = behaviorDecider.evaluate(_state!);
    onStateChanged?.call(_state!, _lastDecision!);
  }

  /// Call when harm/abuse is detected (welfare mechanism).
  void onHarmDetected() {
    if (_state == null) return;

    _state!.emotion = emotionSystem.onEvent(
      _state!.emotion,
      EmotionEvent.harmDetected,
    );
    _state!.needs = needSystem.onInteraction(
      _state!.needs,
      type: InteractionType.negativeGesture,
    );
    _state!.trustScore = (_state!.trustScore - 0.1).clamp(0.0, 1.0);

    _lastDecision = behaviorDecider.evaluate(_state!);
    onStateChanged?.call(_state!, _lastDecision!);
  }
}
