import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import '../models/diary_entry.dart';
import 'database.dart';

/// Data access object for chat_messages and diary_entries.
class ChatDao {
  Future<Database> get _db => LumaDatabase.instance.database;

  // ── Chat messages ──

  Future<int> insertMessage(ChatMessage msg) async {
    final db = await _db;
    return db.insert('chat_messages', msg.toMap());
  }

  /// Get the most recent N messages for working memory (L1).
  Future<List<ChatMessage>> getRecentMessages(
    String petId, {
    int limit = 20,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'chat_messages',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    // Reverse so oldest is first (chronological order).
    return rows.map(ChatMessage.fromMap).toList().reversed.toList();
  }

  /// Count messages today (for token budget control).
  Future<int> countMessagesToday(String petId) async {
    final db = await _db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM chat_messages '
      'WHERE pet_id = ? AND created_at >= ?',
      [petId, startOfDay.toIso8601String()],
    );
    return (result.first['cnt'] as num).toInt();
  }

  // ── Diary entries ──

  Future<int> insertDiaryEntry(DiaryEntry entry) async {
    final db = await _db;
    return db.insert('diary_entries', entry.toMap());
  }

  Future<List<DiaryEntry>> getRecentDiary(
    String petId, {
    int limit = 7,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'diary_entries',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(DiaryEntry.fromMap).toList();
  }
}
