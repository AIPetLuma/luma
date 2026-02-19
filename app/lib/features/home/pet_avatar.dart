import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/emotion.dart';

/// Animated avatar that reflects the pet's emotional state.
///
/// Uses a CustomPainter with a breathing animation (sine wave scaling),
/// emotion-driven colour/particles/glow, and simple face expressions.
class PetAvatar extends StatefulWidget {
  final Emotion emotion;
  final String? conversationStyle;

  const PetAvatar({
    super.key,
    required this.emotion,
    this.conversationStyle,
  });

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _emotionColor(theme);
    final baseSize = _emotionSize();

    return _BreathBuilder(
      animation: _breathController,
      builder: (context, _) {
        // Breathing: sine wave scaling.
        // Arousal controls amplitude: calm = subtle, excited = visible.
        final breathAmplitude = 0.02 + widget.emotion.arousal * 0.04;
        final breathPhase = sin(_breathController.value * 2 * pi);
        final scale = 1.0 + breathAmplitude * breathPhase;

        return SizedBox(
          width: baseSize * 1.3,
          height: baseSize * 1.3,
          child: CustomPaint(
            painter: _LumaPainter(
              color: color,
              breathScale: scale,
              emotion: widget.emotion,
              animProgress: _breathController.value,
            ),
          ),
        );
      },
    );
  }

  Color _emotionColor(ThemeData theme) {
    return switch (widget.emotion.label) {
      'excited' => Colors.amber,
      'content' => Colors.green.shade400,
      'curious' => Colors.blue.shade400,
      'calm' => Colors.teal.shade400,
      'anxious' => Colors.orange.shade400,
      'melancholy' => Colors.indigo.shade300,
      'withdrawn' => Colors.grey,
      _ => theme.colorScheme.primary,
    };
  }

  double _emotionSize() {
    return 140.0 + widget.emotion.arousal * 40;
  }
}

// ── CustomPainter ──

class _LumaPainter extends CustomPainter {
  final Color color;
  final double breathScale;
  final Emotion emotion;
  final double animProgress;

  _LumaPainter({
    required this.color,
    required this.breathScale,
    required this.emotion,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 * 0.55 * breathScale;

    // ── 1. Outer glow ──
    final glowAlpha = (0.08 + emotion.valence.clamp(0.0, 1.0) * 0.05)
        .clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, baseRadius * 1.5, glowPaint);

    // ── 2. Main body ──
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.12),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: baseRadius),
      );
    canvas.drawCircle(center, baseRadius, bodyPaint);

    // ── 3. Inner core ──
    final coreRadius = baseRadius * 0.4;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.2),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, corePaint);

    // ── 4. Border ring ──
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, baseRadius, borderPaint);

    // ── 5. Floating particles (arousal-driven) ──
    final particleCount = (emotion.arousal * 6).round();
    final rng = Random(42); // deterministic seed for consistent pattern
    for (var i = 0; i < particleCount; i++) {
      final angle = (i / max(particleCount, 1)) * 2 * pi +
          animProgress * 2 * pi;
      final orbitRadius = baseRadius * (1.1 + rng.nextDouble() * 0.4);
      final px = center.dx + cos(angle) * orbitRadius;
      final py = center.dy + sin(angle) * orbitRadius;
      final particleSize = 2.0 + rng.nextDouble() * 2;

      final particlePaint = Paint()
        ..color = color.withValues(alpha: 0.3 + rng.nextDouble() * 0.3);
      canvas.drawCircle(Offset(px, py), particleSize, particlePaint);
    }

    // ── 6. Face (valence-driven expression) ──
    _drawFace(canvas, center, baseRadius);
  }

  void _drawFace(Canvas canvas, Offset center, double radius) {
    final eyeY = center.dy - radius * 0.1;
    final eyeSpacing = radius * 0.3;
    final eyeSize = radius * 0.08;
    final eyePaint = Paint()..color = color.withValues(alpha: 0.8);

    final leftEye = Offset(center.dx - eyeSpacing, eyeY);
    final rightEye = Offset(center.dx + eyeSpacing, eyeY);

    if (emotion.label == 'withdrawn') {
      // Closed eyes (horizontal lines).
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        leftEye.translate(-eyeSize, 0),
        leftEye.translate(eyeSize, 0),
        linePaint,
      );
      canvas.drawLine(
        rightEye.translate(-eyeSize, 0),
        rightEye.translate(eyeSize, 0),
        linePaint,
      );
    } else {
      // Open eyes, larger when excited.
      final sizeMultiplier = emotion.arousal > 0.6 ? 1.3 : 1.0;
      canvas.drawCircle(leftEye, eyeSize * sizeMultiplier, eyePaint);
      canvas.drawCircle(rightEye, eyeSize * sizeMultiplier, eyePaint);
    }

    // Mouth: valence drives curve (smile ↔ frown).
    final mouthY = center.dy + radius * 0.15;
    final mouthWidth = radius * 0.25;
    final mouthCurve = emotion.valence * radius * 0.12;

    final mouthPath = Path()
      ..moveTo(center.dx - mouthWidth, mouthY)
      ..quadraticBezierTo(
        center.dx,
        mouthY + mouthCurve, // positive = smile
        center.dx + mouthWidth,
        mouthY,
      );

    final mouthPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(_LumaPainter old) => true;
}

/// Rebuilds child on every animation tick.
class _BreathBuilder extends StatefulWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const _BreathBuilder({required this.animation, required this.builder});

  @override
  State<_BreathBuilder> createState() => _BreathBuilderState();
}

class _BreathBuilderState extends State<_BreathBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_tick);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_tick);
    super.dispose();
  }

  void _tick() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, null);
}
