import 'package:flutter/material.dart';
import '../../data/models/pet_state.dart';
import '../../data/remote/backup_service.dart';
import '../../shared/constants.dart';
import '../../shared/l10n.dart';

/// Settings screen — account, AI disclosure review, data controls.
class SettingsScreen extends StatelessWidget {
  final PetState petState;
  final VoidCallback onBack;
  final VoidCallback onResetPet;
  final ValueChanged<String> onApiKeyChanged;

  const SettingsScreen({
    super.key,
    required this.petState,
    required this.onBack,
    required this.onResetPet,
    required this.onApiKeyChanged,
  });

  void _confirmReset(BuildContext context) {
    final t = L10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.resetConfirmTitle),
        content: Text(
          t.resetConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onResetPet();
            },
            child: Text(t.reset, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(t.settings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Pet info section
          _SectionHeader(title: t.yourLuma),
          _InfoTile(
            icon: Icons.pets,
            title: petState.name,
            subtitle: t.dayTogether(petState.ageDays + 1),
          ),
          _InfoTile(
            icon: Icons.shield_outlined,
            title: t.trustScore,
            subtitle: '${(petState.trustScore * 100).round()}%',
          ),
          _InfoTile(
            icon: Icons.chat_outlined,
            title: t.totalInteractions,
            subtitle: '${petState.totalInteractions}',
          ),

          const Divider(height: 32),

          // AI Disclosure section (compliance: always accessible)
          _SectionHeader(title: t.aboutLuma),
          _DisclosureTile(theme: theme, t: t),

          const Divider(height: 32),

          // Crisis resources (always accessible)
          _SectionHeader(title: t.crisisResources),
          _InfoTile(
            icon: Icons.call_outlined,
            title: t.crisisLifeline,
            subtitle: t.callOrText(LumaConstants.crisisHotlineUS),
          ),
          _InfoTile(
            icon: Icons.textsms_outlined,
            title: t.crisisTextLine,
            subtitle: LumaConstants.crisisTextLine,
          ),

          const Divider(height: 32),

          // API key section
          _SectionHeader(title: t.apiKey),
          _ApiKeyTile(
            onApiKeyChanged: onApiKeyChanged,
            t: t,
          ),

          const Divider(height: 32),

          // Cloud backup section (only shown when Supabase is configured)
          if (BackupService.instance.isAvailable) ...[
            _SectionHeader(title: t.cloudBackup),
            _BackupTile(
              petState: petState,
              t: t,
            ),
            const Divider(height: 32),
          ],

          // Data section
          _SectionHeader(title: t.dataPrivacy),
          _InfoTile(
            icon: Icons.storage_outlined,
            title: t.dataLocal,
            subtitle: BackupService.instance.isAvailable
                ? t.optionalCloudBackup
                : t.noCloudBackup,
          ),

          const SizedBox(height: 16),

          // Reset pet button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                t.resetPet,
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
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

class _ApiKeyTile extends StatefulWidget {
  final ValueChanged<String> onApiKeyChanged;
  final L10n t;

  const _ApiKeyTile({
    required this.onApiKeyChanged,
    required this.t,
  });

  @override
  State<_ApiKeyTile> createState() => _ApiKeyTileState();
}

class _ApiKeyTileState extends State<_ApiKeyTile> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    widget.onApiKeyChanged(key);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: widget.t.anthropicApiKey,
              hintText: widget.t.apiKeyHint,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: Icon(_saved ? Icons.check : Icons.save_outlined),
              label: Text(_saved ? widget.t.saved : widget.t.saveApiKey),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupTile extends StatefulWidget {
  final PetState petState;
  final L10n t;

  const _BackupTile({
    required this.petState,
    required this.t,
  });

  @override
  State<_BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends State<_BackupTile> {
  bool _busy = false;
  String? _status;

  Future<void> _backup() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final ok = await BackupService.instance.backup(widget.petState);
    if (mounted) {
      setState(() {
        _busy = false;
        _status = ok ? widget.t.backedUp : widget.t.backupFailed;
      });
      if (_status != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _status = null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _backup,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_status ?? widget.t.backupToCloud),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclosureTile extends StatelessWidget {
  final ThemeData theme;
  final L10n t;

  const _DisclosureTile({
    required this.theme,
    required this.t,
  });

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
                  t.aiDisclosure,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${t.disclosureMain}\n\n${t.disclosureDetail}',
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
