import 'package:flutter/material.dart';
import '../../data/models/pet_state.dart';
import '../../shared/constants.dart';

/// Settings screen — account, AI disclosure review, data controls.
class SettingsScreen extends StatelessWidget {
  final PetState petState;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.petState,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Pet info section
          _SectionHeader(title: 'Your Luma'),
          _InfoTile(
            icon: Icons.pets,
            title: petState.name,
            subtitle: 'Day ${petState.ageDays + 1} together',
          ),
          _InfoTile(
            icon: Icons.shield_outlined,
            title: 'Trust score',
            subtitle: '${(petState.trustScore * 100).round()}%',
          ),
          _InfoTile(
            icon: Icons.chat_outlined,
            title: 'Total interactions',
            subtitle: '${petState.totalInteractions}',
          ),

          const Divider(height: 32),

          // AI Disclosure section (compliance: always accessible)
          _SectionHeader(title: 'About Luma'),
          _DisclosureTile(theme: theme),

          const Divider(height: 32),

          // Crisis resources (always accessible)
          _SectionHeader(title: 'Crisis resources'),
          _InfoTile(
            icon: Icons.call_outlined,
            title: '988 Suicide & Crisis Lifeline',
            subtitle: 'Call or text ${LumaConstants.crisisHotlineUS}',
          ),
          _InfoTile(
            icon: Icons.textsms_outlined,
            title: 'Crisis Text Line',
            subtitle: LumaConstants.crisisTextLine,
          ),

          const Divider(height: 32),

          // Data section
          _SectionHeader(title: 'Data & privacy'),
          _InfoTile(
            icon: Icons.storage_outlined,
            title: 'All data stays on your device',
            subtitle: 'No cloud backup in this version',
          ),

          const SizedBox(height: 32),

          // App info
          Center(
            child: Text(
              'Luma v0.1.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _DisclosureTile extends StatelessWidget {
  final ThemeData theme;

  const _DisclosureTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Disclosure',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Luma is an AI companion — not a human, '
              'not a real animal, and not a substitute for '
              'professional help.\n\n'
              'Your conversations are processed by an AI system. '
              'Luma has simulated emotions and memory — they feel '
              'real, but they are generated by software.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
