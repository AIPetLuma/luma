import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/l10n.dart';
import '../../shared/runtime_env.dart';

/// Final onboarding step — the user names their pet.
class NameScreen extends StatefulWidget {
  final void Function(String name) onNamed;

  const NameScreen({super.key, required this.onNamed});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _controller.text.trim();
    return text.isNotEmpty && text.length <= 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);
    final shouldAnimate = !isRunningWidgetTest;

    Widget eggBlock = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.egg_outlined,
        size: 56,
        color: theme.colorScheme.primary,
      ),
    );
    if (shouldAnimate) {
      eggBlock = eggBlock
          .animate()
          .scaleXY(begin: 1.0, end: 1.05, duration: 700.ms)
          .then()
          .scaleXY(begin: 1.05, end: 1.0, duration: 700.ms)
          .then()
          .shimmer(
              duration: 1200.ms,
              color: theme.colorScheme.primary.withValues(alpha: 0.3));
    }

    Widget promptBlock = Text(
      t.whatWillYouCall,
      style: theme.textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
    if (shouldAnimate) {
      promptBlock =
          promptBlock.animate().fadeIn(delay: 300.ms, duration: 500.ms);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nameYourLuma),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Egg / hatching illustration placeholder
              eggBlock,
              const SizedBox(height: 32),

              promptBlock,
              const SizedBox(height: 8),
              Text(
                t.chooseCarefully,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Name input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: t.typeAName,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onSubmitted: _isValid ? (_) => _submit() : null,
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isValid ? _submit : null,
                  child: Text(t.bringToLife),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_isValid) {
      widget.onNamed(_controller.text.trim());
    }
  }
}
