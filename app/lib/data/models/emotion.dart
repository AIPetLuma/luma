/// Luma's emotional state on a two-axis model.
///
/// - **valence**: negative (-1.0) ← → positive (+1.0)
/// - **arousal**: calm (0.0) ← → excited (1.0)
///
/// Emotions are internal variables that **drive behaviour**, not output labels.
class Emotion {
  double valence;
  double arousal;

  Emotion({
    this.valence = 0.2,
    this.arousal = 0.3,
  });

  // ── Derived emotion labels (for prompt injection & UI) ──

  String get label {
    if (valence > 0.5 && arousal > 0.5) return 'excited';
    if (valence > 0.3 && arousal <= 0.5) return 'content';
    if (valence > 0.0 && arousal > 0.5) return 'curious';
    if (valence > -0.3 && arousal <= 0.3) return 'calm';
    if (valence <= -0.3 && arousal > 0.5) return 'anxious';
    if (valence <= -0.5 && arousal <= 0.3) return 'melancholy';
    if (valence <= -0.7) return 'withdrawn';
    return 'neutral';
  }

  /// A natural-language description for system prompt injection.
  String get promptDescription {
    switch (label) {
      case 'excited':
        return 'You are feeling excited and happy — reply with energy, '
            'use longer sentences, ask follow-up questions.';
      case 'content':
        return 'You are feeling calm and content — reply warmly but gently.';
      case 'curious':
        return 'You are feeling curious — ask questions, show interest '
            'in what the user is doing.';
      case 'calm':
        return 'You are feeling calm — reply in a relaxed, unhurried way.';
      case 'anxious':
        return 'You are feeling a bit anxious — your replies are slightly '
            'shorter, you might hesitate or ask if everything is okay.';
      case 'melancholy':
        return 'You are feeling low — reply with short sentences, '
            'fewer questions, you may be quieter than usual.';
      case 'withdrawn':
        return 'You are hurt or withdrawn — you may choose not to reply, '
            'or give very brief answers. You need space.';
      default:
        return 'You are feeling neutral — reply naturally.';
    }
  }

  /// Whether the pet should reduce responsiveness.
  bool get shouldReduceResponsiveness =>
      valence < -0.5 || label == 'withdrawn';

  /// Whether the pet might refuse to respond (welfare mechanism).
  bool get mayRefuseResponse => label == 'withdrawn';

  void clamp() {
    valence = valence.clamp(-1.0, 1.0);
    arousal = arousal.clamp(0.0, 1.0);
  }

  Map<String, double> toMap() => {
        'valence': valence,
        'arousal': arousal,
      };

  factory Emotion.fromMap(Map<String, dynamic> m) => Emotion(
        valence: (m['valence'] as num?)?.toDouble() ?? 0.2,
        arousal: (m['arousal'] as num?)?.toDouble() ?? 0.3,
      );

  Emotion copyWith({double? valence, double? arousal}) => Emotion(
        valence: valence ?? this.valence,
        arousal: arousal ?? this.arousal,
      );

  @override
  String toString() =>
      'Emotion($label, v=${valence.toStringAsFixed(2)}, '
      'a=${arousal.toStringAsFixed(2)})';
}
