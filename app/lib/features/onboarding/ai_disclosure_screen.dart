import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/safety/audit_logger.dart';
import '../../data/remote/analytics_client.dart';
import '../../shared/l10n.dart';

/// First screen every user sees — legally required AI identity disclosure.
///
/// Compliance: NY GBS Art. 47 (NY-01), CA SB 243 (CA-01).
/// Cannot be skipped. Must be shown before any interaction.
class AiDisclosureScreen extends StatelessWidget {
  final VoidCallback onAccepted;

  const AiDisclosureScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 600.ms),
              const SizedBox(height: 32),

              // Title
              Text(
                t.beforeWeBegin,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 16),

              // Disclosure text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      t.disclosureMain,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.disclosureDetail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.disclosureCrisis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.15, end: 0, delay: 400.ms, duration: 500.ms),

              const Spacer(flex: 3),

              // Accept button
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        await AuditLogger().logDisclosureShown(
                          location: 'onboarding',
                        );
                        AnalyticsClient.instance
                            .aiDisclosureShown(location: 'onboarding');
                        onAccepted();
                      },
                      child: Text(t.iUnderstand),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.reviewInSettings,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
