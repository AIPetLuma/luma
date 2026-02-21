import 'package:flutter/foundation.dart';
import 'supabase_client_service.dart';

/// Writes experiment events to Supabase.
///
/// D1/D7/D21 marks are generated server-side by SQL trigger logic.
class RetentionService {
  RetentionService._();

  static final RetentionService instance = RetentionService._();

  Future<void> recordSignup({required String petId, DateTime? at}) async {
    await _record(
      eventName: 'signup_completed',
      petId: petId,
      at: at,
    );
  }

  Future<void> recordSessionStarted({required String petId, DateTime? at}) async {
    await _record(
      eventName: 'session_started',
      petId: petId,
      at: at,
    );
  }

  Future<void> recordSessionEnded({
    required String petId,
    required int durationSeconds,
    DateTime? at,
  }) async {
    await _record(
      eventName: 'session_ended',
      petId: petId,
      at: at,
      properties: {'duration_s': durationSeconds},
    );
  }

  Future<void> _record({
    required String eventName,
    required String petId,
    DateTime? at,
    Map<String, dynamic>? properties,
  }) async {
    final supabase = SupabaseClientService.instance;
    if (!supabase.isAvailable) return;

    final hasSession = await supabase.ensureAnonymousSession();
    if (!hasSession) return;

    final client = supabase.client;
    final ownerId = supabase.userId;
    if (client == null || ownerId == null) return;

    try {
      await client.from('experiment_events').insert({
        'owner_id': ownerId,
        'pet_id': petId,
        'event_name': eventName,
        'event_at': (at ?? DateTime.now()).toIso8601String(),
        'properties': properties ?? <String, dynamic>{},
      });
    } catch (e) {
      debugPrint('RetentionService: failed to record $eventName ($e).');
    }
  }
}
