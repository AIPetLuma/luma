/// A single memory entry in Luma's three-layer memory system.
///
/// - **L1 (working)**: raw conversation turns, kept in-memory only.
/// - **L2 (short-term)**: conversation summaries, stored 30 days.
/// - **L3 (long-term)**: key events & user profile, stored permanently.
class MemoryEntry {
  final int? id;
  final String petId;
  final MemoryLevel level;
  final String content;
  final String? emotionTag;
  final double importance;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const MemoryEntry({
    this.id,
    required this.petId,
    required this.level,
    required this.content,
    this.emotionTag,
    this.importance = 0.5,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pet_id': petId,
        'level': level.index,
        'content': content,
        'emotion_tag': emotionTag,
        'importance': importance,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

  factory MemoryEntry.fromMap(Map<String, dynamic> m) => MemoryEntry(
        id: m['id'] as int?,
        petId: m['pet_id'] as String,
        level: MemoryLevel.values[(m['level'] as num).toInt()],
        content: m['content'] as String,
        emotionTag: m['emotion_tag'] as String?,
        importance: (m['importance'] as num?)?.toDouble() ?? 0.5,
        createdAt: DateTime.parse(m['created_at'] as String),
        expiresAt: m['expires_at'] != null
            ? DateTime.parse(m['expires_at'] as String)
            : null,
      );
}

enum MemoryLevel {
  working,   // L1 — current conversation context
  shortTerm, // L2 — conversation summaries (30 days)
  longTerm,  // L3 — key events (permanent)
}
