import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton database helper for Luma's local SQLite storage.
///
/// All pet state, memories, chat history, diary entries, and audit logs
/// are persisted here. Data never leaves the device unless the user
/// explicitly opts into cloud backup (not in MVP).
class LumaDatabase {
  static const _dbName = 'luma.db';
  static const _dbVersion = 1;

  LumaDatabase._();
  static final instance = LumaDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pet_state (
        id                TEXT PRIMARY KEY,
        name              TEXT NOT NULL,
        birthday          TEXT NOT NULL,
        personality       TEXT NOT NULL,
        need_loneliness   REAL DEFAULT 0.5,
        need_curiosity    REAL DEFAULT 0.5,
        need_fatigue      REAL DEFAULT 0.0,
        need_security     REAL DEFAULT 0.5,
        emotion_valence   REAL DEFAULT 0.2,
        emotion_arousal   REAL DEFAULT 0.3,
        trust_score       REAL DEFAULT 0.5,
        last_active_at    TEXT NOT NULL,
        total_interactions INTEGER DEFAULT 0,
        created_at        TEXT NOT NULL,
        updated_at        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE memories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id      TEXT NOT NULL,
        level       INTEGER NOT NULL,
        content     TEXT NOT NULL,
        emotion_tag TEXT,
        importance  REAL DEFAULT 0.5,
        created_at  TEXT NOT NULL,
        expires_at  TEXT,
        FOREIGN KEY (pet_id) REFERENCES pet_state(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id            TEXT NOT NULL,
        role              TEXT NOT NULL,
        content           TEXT NOT NULL,
        emotion_snapshot  TEXT,
        risk_level        INTEGER DEFAULT 0,
        created_at        TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pet_state(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE diary_entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id      TEXT NOT NULL,
        content     TEXT NOT NULL,
        mood        TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pet_state(id)
      )
    ''');

    // Audit logs — append-only, never deleted (compliance).
    await db.execute('''
      CREATE TABLE audit_logs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type  TEXT NOT NULL,
        risk_level  INTEGER,
        detail      TEXT NOT NULL,
        created_at  TEXT NOT NULL
      )
    ''');

    // Indices for common queries.
    await db.execute(
        'CREATE INDEX idx_memories_pet_level ON memories(pet_id, level)');
    await db.execute(
        'CREATE INDEX idx_chat_pet_time ON chat_messages(pet_id, created_at)');
    await db.execute(
        'CREATE INDEX idx_diary_pet_time ON diary_entries(pet_id, created_at)');
  }
}
