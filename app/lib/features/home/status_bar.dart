import 'package:flutter/material.dart';
import '../../data/models/pet_state.dart';

/// Horizontal status bar showing the pet's four needs and emotion axes.
class StatusBar extends StatelessWidget {
  final PetState petState;

  const StatusBar({super.key, required this.petState});

  @override
  Widget build(BuildContext context) {
    final needs = petState.needs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NeedIndicator(
                  icon: Icons.favorite_outline,
                  label: 'Lonely',
                  value: needs.loneliness,
                  color: Colors.pink,
                  inverted: true, // high = bad
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NeedIndicator(
                  icon: Icons.explore_outlined,
                  label: 'Curious',
                  value: needs.curiosity,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NeedIndicator(
                  icon: Icons.bedtime_outlined,
                  label: 'Tired',
                  value: needs.fatigue,
                  color: Colors.purple,
                  inverted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NeedIndicator(
                  icon: Icons.shield_outlined,
                  label: 'Trust',
                  value: needs.security,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeedIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool inverted;

  const _NeedIndicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // For inverted needs (loneliness, fatigue), high value = warning colour.
    final effectiveColor = (inverted && value > 0.7)
        ? Colors.red
        : color;

    return Column(
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(height: 4),
        SizedBox(
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(effectiveColor),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
