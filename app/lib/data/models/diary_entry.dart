/// An entry in the pet's diary — generated during offline periods
/// to give the user a sense that the pet "lived through" the time apart.
class DiaryEntry {
  final int? id;
  final String petId;
  final String content;
  final String mood;
  final DateTime createdAt;

  const DiaryEntry({
    this.id,
    required this.petId,
    required this.content,
    required this.mood,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pet_id': petId,
        'content': content,
        'mood': mood,
        'created_at': createdAt.toIso8601String(),
      };

  factory DiaryEntry.fromMap(Map<String, dynamic> m) => DiaryEntry(
        id: m['id'] as int?,
        petId: m['pet_id'] as String,
        content: m['content'] as String,
        mood: m['mood'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
