import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/pet_state.dart';
import 'chat_controller.dart';
import '../../shared/l10n.dart';
import 'crisis_card.dart';
import 'disclosure_reminder.dart';

/// Full-screen chat interface between user and pet.
class ChatScreen extends StatefulWidget {
  final PetState petState;
  final List<ChatMessage> messages;
  final bool showDisclosureReminder;
  final Future<ChatResult> Function(String text) onSendMessage;
  final VoidCallback onDisclosureDismissed;
  final VoidCallback onBack;

  const ChatScreen({
    super.key,
    required this.petState,
    required this.messages,
    required this.showDisclosureReminder,
    required this.onSendMessage,
    required this.onDisclosureDismissed,
    required this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  static const _warningInvalidApiKey = 'invalid_api_key';
  bool _isSending = false;
  _InlineCrisis? _activeCrisis;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            Text(
              widget.petState.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t.emotionText(widget.petState.emotion.label),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Disclosure reminder (shown every 3 hours per compliance)
          if (widget.showDisclosureReminder)
            DisclosureReminder(onDismiss: widget.onDisclosureDismissed),

          // Message list
          Expanded(
            child: widget.messages.isEmpty
                ? _EmptyChat(petName: widget.petState.name)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: widget.messages.length +
                        (_activeCrisis != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Insert crisis card after the triggering message.
                      if (_activeCrisis != null &&
                          index == _activeCrisis!.afterIndex + 1) {
                        return CrisisCard(
                          riskLevel: _activeCrisis!.riskLevel,
                          message: _activeCrisis!.message,
                        );
                      }

                      final msgIndex = _activeCrisis != null &&
                              index > _activeCrisis!.afterIndex
                          ? index - 1
                          : index;

                      if (msgIndex >= widget.messages.length) {
                        return const SizedBox.shrink();
                      }

                      final msg = widget.messages[msgIndex];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),

          // Input bar
          _InputBar(
            controller: _textController,
            isSending: _isSending,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final result = await widget.onSendMessage(text);

      if (result.warningCode != null) {
        _showWarning(result.warningCode!);
      }

      if (result.isCrisis && result.crisisMessage != null) {
        setState(() {
          _activeCrisis = _InlineCrisis(
            afterIndex: widget.messages.length - 1,
            riskLevel: result.riskLevel,
            message: result.crisisMessage!,
          );
        });
      } else {
        _activeCrisis = null;
      }
    } catch (e) {
      debugPrint('Chat send failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).sendMessageFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _showWarning(String warningCode) {
    final t = L10n.of(context);
    String message;
    if (warningCode == _warningInvalidApiKey) {
      message = t.invalidApiKeyWarning;
    } else if (warningCode.startsWith(kChatWarningHttpErrorPrefix)) {
      final suffix = warningCode.substring(kChatWarningHttpErrorPrefix.length);
      final status = int.tryParse(suffix);
      message = status == null
          ? t.httpRequestFailedUnknown
          : t.httpRequestFailedWithStatus(status);
    } else {
      message = t.sendMessageFailed;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ── Message bubble ──

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const SizedBox(width: 4),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Empty state ──

class _EmptyChat extends StatelessWidget {
  final String petName;

  const _EmptyChat({required this.petName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              L10n.of(context).sayHelloTo(petName),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context).conversationBeginsHere,
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

// ── Input bar ──

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewPadding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: L10n.of(context).typeAMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          isSending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}

// ── Internal data ──

class _InlineCrisis {
  final int afterIndex;
  final int riskLevel;
  final String message;

  const _InlineCrisis({
    required this.afterIndex,
    required this.riskLevel,
    required this.message,
  });
}

/// Re-export for convenience — matches ChatController's ChatResult.
class ChatResult {
  final String reply;
  final bool isCrisis;
  final int riskLevel;
  final String? crisisMessage;
  final String? emotion;
  final String? warningCode;

  const ChatResult({
    required this.reply,
    required this.isCrisis,
    required this.riskLevel,
    this.crisisMessage,
    this.emotion,
    this.warningCode,
  });
}
