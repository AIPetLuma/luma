import 'package:flutter/material.dart';
import '../../core/identity/pet_identity.dart';

/// Personality selection screen — the user chooses who their pet will be.
class BirthScreen extends StatefulWidget {
  final void Function(PersonalityPreset? preset) onSelected;

  const BirthScreen({super.key, required this.onSelected});

  @override
  State<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends State<BirthScreen> {
  PersonalityPreset? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a personality'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Every Luma is unique. Pick a starting personality — '
                'it will evolve as you spend time together.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Preset cards
              Expanded(
                child: ListView(
                  children: [
                    for (final preset in PersonalityPreset.values)
                      _PresetCard(
                        preset: preset,
                        isSelected: _selected == preset,
                        onTap: () => setState(() => _selected = preset),
                      ),
                    // Random option
                    _PresetCard(
                      preset: null,
                      isSelected: _selected == null && _hasExplicitlyChosen,
                      onTap: () => setState(() {
                        _selected = null;
                        _hasExplicitlyChosen = true;
                      }),
                    ),
                  ],
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: (_selected != null || _hasExplicitlyChosen)
                      ? () => widget.onSelected(_selected)
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasExplicitlyChosen = false;
}

class _PresetCard extends StatelessWidget {
  final PersonalityPreset? preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = preset?.label ?? 'Surprise me';
    final description =
        preset?.description ?? 'A completely random personality — who knows!';
    final icon = switch (preset) {
      PersonalityPreset.curious => Icons.explore_outlined,
      PersonalityPreset.gentle => Icons.favorite_outline,
      PersonalityPreset.playful => Icons.celebration_outlined,
      PersonalityPreset.shy => Icons.nights_stay_outlined,
      null => Icons.shuffle,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
