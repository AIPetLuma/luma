import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/identity/pet_identity.dart';
import '../../shared/l10n.dart';
import '../../shared/runtime_env.dart';

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
    final t = L10n.of(context);
    final shouldAnimate = !isRunningWidgetTest;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.choosePersonality),
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
                t.personalityHint,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Preset cards
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < PersonalityPreset.values.length; i++)
                      (() {
                        Widget card = _PresetCard(
                          preset: PersonalityPreset.values[i],
                          isSelected: _selected == PersonalityPreset.values[i],
                          onTap: () => setState(
                              () => _selected = PersonalityPreset.values[i]),
                        );
                        if (shouldAnimate) {
                          card = card
                              .animate()
                              .fadeIn(delay: (100 * i).ms, duration: 400.ms)
                              .slideX(
                                  begin: 0.1,
                                  end: 0,
                                  delay: (100 * i).ms,
                                  duration: 400.ms);
                        }
                        return card;
                      })(),
                    // Random option
                    (() {
                      Widget card = _PresetCard(
                        preset: null,
                        isSelected: _selected == null && _hasExplicitlyChosen,
                        onTap: () => setState(() {
                          _selected = null;
                          _hasExplicitlyChosen = true;
                        }),
                      );
                      if (shouldAnimate) {
                        card = card
                            .animate()
                            .fadeIn(
                                delay: (100 * PersonalityPreset.values.length)
                                    .ms,
                                duration: 400.ms)
                            .slideX(
                                begin: 0.1,
                                end: 0,
                                delay: (100 * PersonalityPreset.values.length)
                                    .ms,
                                duration: 400.ms);
                      }
                      return card;
                    })(),
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
                  child: Text(t.continueButton),
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
    final t = L10n.of(context);

    final label = switch (preset) {
      PersonalityPreset.curious => t.explorerPreset,
      PersonalityPreset.gentle => t.gentleSoulPreset,
      PersonalityPreset.playful => t.playfulSpiritPreset,
      PersonalityPreset.shy => t.shyDreamerPreset,
      null => t.surpriseMe,
    };

    final description = switch (preset) {
      PersonalityPreset.curious => t.explorerPresetDescription,
      PersonalityPreset.gentle => t.gentleSoulPresetDescription,
      PersonalityPreset.playful => t.playfulSpiritPresetDescription,
      PersonalityPreset.shy => t.shyDreamerPresetDescription,
      null => t.surpriseDescription,
    };
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
