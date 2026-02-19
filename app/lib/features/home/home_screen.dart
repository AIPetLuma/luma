import 'package:flutter/material.dart';
import '../../data/models/pet_state.dart';
import '../../data/models/diary_entry.dart';
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
                          'Day ${petState.ageDays + 1}',
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
            ),

            // Emotion label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _emotionText(petState.emotion.label),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

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
                      label: Text(
                        'Diary (${diaryEntries.length})',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Chat button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onChatTap,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Talk'),
                    ),
                  ),
                ],
              ),
            ),
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

  String _emotionText(String label) {
    return switch (label) {
      'excited' => 'Feeling excited!',
      'content' => 'Feeling content',
      'curious' => 'Feeling curious',
      'calm' => 'Feeling calm',
      'anxious' => 'Feeling a bit anxious',
      'melancholy' => 'Feeling low...',
      'withdrawn' => 'Needs some space',
      _ => 'Feeling okay',
    };
  }
}
