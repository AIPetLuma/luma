import 'package:sqflite/sqflite.dart';
import '../models/memory_entry.dart';
import 'database.dart';

/// Data access object for the memories table.
class MemoryDao {
  Future<Database> get _db => LumaDatabase.instance.database;

  Future<int> insert(MemoryEntry entry) async {
    final db = await _db;
    return db.insert('memories', entry.toMap());
  }

  /// Get recent short-term memories (L2) for prompt context.
  Future<List<MemoryEntry>> getRecentShortTerm(
    String petId, {
    int limit = 10,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'memories',
      where: 'pet_id = ? AND level = ?',
      whereArgs: [petId, MemoryLevel.shortTerm.index],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  /// Get all long-term memories (L3) — permanent, small set.
  Future<List<MemoryEntry>> getLongTerm(String petId) async {
    final db = await _db;
    final rows = await db.query(
      'memories',
      where: 'pet_id = ? AND level = ?',
      whereArgs: [petId, MemoryLevel.longTerm.index],
      orderBy: 'importance DESC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  /// Delete expired short-term memories.
  Future<int> deleteExpired() async {
    final db = await _db;
    return db.delete(
      'memories',
      where: 'level = ? AND expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [
        MemoryLevel.shortTerm.index,
        DateTime.now().toIso8601String(),
      ],
    );
  }
}
