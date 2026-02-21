import 'package:flutter/material.dart';
import '../../core/safety/audit_logger.dart';
import '../../shared/l10n.dart';

/// Periodic reminder that Luma is AI (shown every 3 hours).
///
/// Compliance: NY GBS Art. 47 (NY-01) — periodic re-disclosure.
class DisclosureReminder extends StatelessWidget {
  final VoidCallback onDismiss;

  const DisclosureReminder({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);

    // Log that the disclosure was shown (compliance).
    AuditLogger().logDisclosureShown(location: 'chat_reminder');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.disclosureReminder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
