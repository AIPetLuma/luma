/// A single chat message between the user and the pet.
class ChatMessage {
  final int? id;
  final String petId;
  final ChatRole role;
  final String content;
  final String? emotionSnapshot; // JSON of emotion at send time
  final int riskLevel; // 0-3, from crisis detector
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.petId,
    required this.role,
    required this.content,
    this.emotionSnapshot,
    this.riskLevel = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pet_id': petId,
        'role': role.name,
        'content': content,
        'emotion_snapshot': emotionSnapshot,
        'risk_level': riskLevel,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as int?,
        petId: m['pet_id'] as String,
        role: ChatRole.values.byName(m['role'] as String),
        content: m['content'] as String,
        emotionSnapshot: m['emotion_snapshot'] as String?,
        riskLevel: (m['risk_level'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

enum ChatRole { user, pet }
