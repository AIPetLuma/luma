import 'memory_manager.dart';

/// Predefined key events that should be promoted to L3 (permanent memory).
///
/// These are the moments that make the relationship irreplaceable —
/// "it remembers every day you spent together".
class EventMemory {
  final MemoryManager _manager;

  EventMemory({required MemoryManager manager}) : _manager = manager;

  /// Record the moment the pet was born (first meeting).
  Future<void> recordBirth(String petId, String ownerName) async {
    await _manager.recordKeyEvent(
      petId,
      description: 'I was born today! My owner\'s name is $ownerName. '
          'This is the beginning of our story together.',
      importance: 1.0,
      emotionTag: 'excited',
    );
  }

  /// Record when the owner shared their name.
  Future<void> recordOwnerName(String petId, String name) async {
    await _manager.recordKeyEvent(
      petId,
      description: 'My owner told me their name is $name.',
      importance: 0.9,
    );
  }

  /// Record a milestone (e.g. 7 days together, 100 messages).
  Future<void> recordMilestone(
    String petId, {
    required String milestone,
  }) async {
    await _manager.recordKeyEvent(
      petId,
      description: milestone,
      importance: 0.8,
      emotionTag: 'content',
    );
  }

  /// Record when the user shared something emotionally significant.
  Future<void> recordEmotionalMoment(
    String petId, {
    required String description,
    required String emotionTag,
  }) async {
    await _manager.recordKeyEvent(
      petId,
      description: description,
      importance: 0.85,
      emotionTag: emotionTag,
    );
  }
}
