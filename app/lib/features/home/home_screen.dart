import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/pet_state.dart';
import '../../data/models/diary_entry.dart';
import '../../shared/l10n.dart';
import 'pet_avatar.dart';
import 'status_bar.dart';
import 'diary_sheet.dart';

/// Main home screen showing the pet, its emotional state, and navigation.
class HomeScreen extends StatelessWidget {
  final PetState petState;
  final List<DiaryEntry> diaryEntries;
  final VoidCallback onChatTap;
  final VoidCallback onSettingsTap;

  const HomeScreen({
    super.key,
    required this.petState,
    required this.diaryEntries,
    required this.onChatTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: name + settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petState.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          t.day(petState.ageDays + 1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ),

            // Status bar (needs + emotion)
            StatusBar(petState: petState),

            // Pet avatar (central, takes remaining space)
            Expanded(
              child: GestureDetector(
                onTap: onChatTap,
                child: Center(
                  child: PetAvatar(
                    emotion: petState.emotion,
                    conversationStyle: null,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOutBack),

            // Emotion label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                t.emotionText(petState.emotion.label),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms),

            // Bottom bar: diary + chat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Diary button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: diaryEntries.isEmpty
                          ? null
                          : () => _showDiary(context),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(t.diary(diaryEntries.length)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Chat button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onChatTap,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(t.talk),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  void _showDiary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DiarySheet(entries: diaryEntries),
    );
  }
}
