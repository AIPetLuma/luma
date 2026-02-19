import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_state.dart';

/// Optional cloud backup via Supabase.
///
/// All data is local-first (SQLite). This service provides opt-in
/// backup/restore so users can transfer their pet between devices.
///
/// Requires Supabase project URL and anon key via `--dart-define`:
///   SUPABASE_URL, SUPABASE_ANON_KEY
class BackupService {
  SupabaseClient? _client;

  BackupService._();

  static final BackupService instance = BackupService._();

  bool get isAvailable => _client != null;

  /// Initialise Supabase. No-op if credentials are missing.
  Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('BackupService: no Supabase credentials — disabled.');
      return;
    }
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _client = Supabase.instance.client;
      debugPrint('BackupService: Supabase connected.');
    } catch (e) {
      debugPrint('BackupService: init failed ($e) — disabled.');
    }
  }

  /// Upload the current pet state to Supabase.
  ///
  /// Uses upsert so the same pet ID overwrites the previous backup.
  Future<bool> backup(PetState pet) async {
    if (_client == null) return false;
    try {
      final data = pet.toMap();
      data['backed_up_at'] = DateTime.now().toIso8601String();
      await _client!.from('pet_backups').upsert(data);
      debugPrint('BackupService: pet "${pet.name}" backed up.');
      return true;
    } catch (e) {
      debugPrint('BackupService: backup failed ($e).');
      return false;
    }
  }

  /// Restore a pet state from Supabase by ID.
  ///
  /// Returns null if no backup exists or the service is unavailable.
  Future<PetState?> restore(String petId) async {
    if (_client == null) return null;
    try {
      final response = await _client!
          .from('pet_backups')
          .select()
          .eq('id', petId)
          .maybeSingle();
      if (response == null) return null;
      return PetState.fromMap(response);
    } catch (e) {
      debugPrint('BackupService: restore failed ($e).');
      return null;
    }
  }

  /// List all backed-up pets (for device transfer).
  Future<List<Map<String, dynamic>>> listBackups() async {
    if (_client == null) return [];
    try {
      final response = await _client!
          .from('pet_backups')
          .select('id, name, backed_up_at')
          .order('backed_up_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('BackupService: list failed ($e).');
      return [];
    }
  }
}
