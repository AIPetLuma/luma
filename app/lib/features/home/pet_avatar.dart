import 'package:flutter/material.dart';
import '../../data/models/emotion.dart';

/// Animated avatar that reflects the pet's emotional state.
///
/// MVP uses simple shape + colour changes. Phase C will add
/// Rive/Lottie animations.
class PetAvatar extends StatelessWidget {
  final Emotion emotion;
  final String? conversationStyle;

  const PetAvatar({
    super.key,
    required this.emotion,
    this.conversationStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _emotionColor(theme);
    final size = _emotionSize();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _emotionEmoji(),
            key: ValueKey(emotion.label),
            style: TextStyle(fontSize: size * 0.4),
          ),
        ),
      ),
    );
  }

  Color _emotionColor(ThemeData theme) {
    return switch (emotion.label) {
      'excited' => Colors.amber,
      'content' => Colors.green,
      'curious' => Colors.blue,
      'calm' => Colors.teal,
      'anxious' => Colors.orange,
      'melancholy' => Colors.indigo,
      'withdrawn' => Colors.grey,
      _ => theme.colorScheme.primary,
    };
  }

  double _emotionSize() {
    // Higher arousal → bigger (more energetic), lower → smaller (subdued).
    final base = 140.0;
    final arousalBonus = emotion.arousal * 40;
    return base + arousalBonus;
  }

  String _emotionEmoji() {
    return switch (emotion.label) {
      'excited' => '\u{1F60A}',   // smiling face
      'content' => '\u{1F60C}',   // relieved
      'curious' => '\u{1F9D0}',   // monocle
      'calm' => '\u{1F60C}',      // relieved
      'anxious' => '\u{1F630}',   // cold sweat
      'melancholy' => '\u{1F614}', // pensive
      'withdrawn' => '\u{1F636}',  // no mouth
      _ => '\u{1F43E}',            // paw prints
    };
  }
}
