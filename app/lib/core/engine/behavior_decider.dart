import '../../data/models/emotion.dart';
import '../../data/models/need.dart';
import '../../data/models/pet_state.dart';

/// Translates the pet's internal state into concrete behaviour decisions.
///
/// This is where "emotions drive behaviour" becomes real — the decider
/// determines whether the pet should initiate contact, refuse to respond,
/// generate a diary entry, or adjust its conversation style.
class BehaviorDecider {
  /// Evaluate what actions the pet should take right now.
  BehaviorDecision evaluate(PetState state) {
    final actions = <PetAction>[];

    // ── Should the pet reach out to the owner? ──
    if (state.needs.loneliness >= 0.8) {
      actions.add(PetAction.reachOut);
    }

    // ── Should the pet generate a diary entry? ──
    if (state.needs.curiosity > 0.7 && state.emotion.arousal > 0.4) {
      actions.add(PetAction.writeDiary);
    }

    // ── Should the pet enter sleep mode? ──
    if (state.needs.fatigue >= 0.9) {
      actions.add(PetAction.sleep);
    }

    // ── Should the pet withdraw (welfare mechanism)? ──
    if (state.emotion.mayRefuseResponse || state.needs.security < 0.2) {
      actions.add(PetAction.withdraw);
    }

    return BehaviorDecision(
      actions: actions,
      conversationStyle: _resolveStyle(state),
      shouldInitiateContact: actions.contains(PetAction.reachOut),
    );
  }

  ConversationStyle _resolveStyle(PetState state) {
    final emotion = state.emotion;
    final needs = state.needs;

    // Withdrawn — minimal responses.
    if (emotion.mayRefuseResponse) {
      return ConversationStyle.withdrawn;
    }

    // Very tired — brief and slow.
    if (needs.fatigue >= 0.8) {
      return ConversationStyle.sleepy;
    }

    // Sad / lonely — short, quiet.
    if (emotion.valence < -0.3) {
      return ConversationStyle.melancholy;
    }

    // Curious and energetic — chatty, asks questions.
    if (needs.curiosity > 0.6 && emotion.arousal > 0.4) {
      return ConversationStyle.curious;
    }

    // Happy — warm and engaged.
    if (emotion.valence > 0.3) {
      return ConversationStyle.happy;
    }

    return ConversationStyle.neutral;
  }
}

class BehaviorDecision {
  final List<PetAction> actions;
  final ConversationStyle conversationStyle;
  final bool shouldInitiateContact;

  const BehaviorDecision({
    required this.actions,
    required this.conversationStyle,
    required this.shouldInitiateContact,
  });
}

enum PetAction {
  reachOut,   // send push notification
  writeDiary, // generate diary entry
  sleep,      // enter low-responsiveness mode
  withdraw,   // welfare: refuse to respond
}

enum ConversationStyle {
  happy,
  curious,
  neutral,
  melancholy,
  sleepy,
  withdrawn,
}
