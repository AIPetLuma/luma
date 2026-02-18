import 'package:sqflite/sqflite.dart';
import '../models/pet_state.dart';
import 'database.dart';

/// Data access object for the pet_state table.
class PetDao {
  Future<Database> get _db => LumaDatabase.instance.database;

  /// Insert a new pet (called once at "birth").
  Future<void> insert(PetState pet) async {
    final db = await _db;
    await db.insert('pet_state', pet.toMap());
  }

  /// Load the pet. Returns null if no pet exists yet.
  Future<PetState?> load() async {
    final db = await _db;
    final rows = await db.query('pet_state', limit: 1);
    if (rows.isEmpty) return null;
    return PetState.fromMap(rows.first);
  }

  /// Persist the full state snapshot (called every tick).
  Future<void> update(PetState pet) async {
    final db = await _db;
    pet.updatedAt = DateTime.now();
    await db.update(
      'pet_state',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }
}
