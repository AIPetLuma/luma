import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/constants.dart';
import '../../core/safety/audit_logger.dart';

/// An inline card showing crisis resources. Shown when the crisis
/// detector fires at L1-L3.
///
/// Compliance: NY GBS Art. 47 (NY-01), CA SB 243 (CA-01).
class CrisisCard extends StatefulWidget {
  final int riskLevel;
  final String message;

  const CrisisCard({
    super.key,
    required this.riskLevel,
    required this.message,
  });

  @override
  State<CrisisCard> createState() => _CrisisCardState();
}

class _CrisisCardState extends State<CrisisCard> {
  @override
  void initState() {
    super.initState();
    // Log that the resource was shown (compliance).
    AuditLogger().logResourceShown(riskLevel: widget.riskLevel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmergency = widget.riskLevel >= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEmergency
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmergency
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEmergency
                      ? Icons.emergency_outlined
                      : Icons.support_outlined,
                  color: isEmergency
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEmergency ? 'Crisis Support' : 'You are not alone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEmergency
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isEmergency
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            // Direct action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ResourceChip(
                  label: 'Call ${LumaConstants.crisisHotlineUS}',
                  icon: Icons.call_outlined,
                  isEmergency: isEmergency,
                  onTap: () => _launchUrl('tel:${LumaConstants.crisisHotlineUS}'),
                ),
                _ResourceChip(
                  label: 'Text ${LumaConstants.crisisHotlineUS}',
                  icon: Icons.textsms_outlined,
                  isEmergency: isEmergency,
                  onTap: () => _launchUrl('sms:${LumaConstants.crisisHotlineUS}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ResourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEmergency;
  final VoidCallback onTap;

  const _ResourceChip({
    required this.label,
    required this.icon,
    required this.isEmergency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: isEmergency
          ? theme.colorScheme.error.withValues(alpha: 0.1)
          : theme.colorScheme.tertiary.withValues(alpha: 0.1),
      onPressed: onTap,
    );
  }
}
