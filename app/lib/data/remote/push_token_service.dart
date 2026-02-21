import 'package:flutter/foundation.dart';
import 'supabase_client_service.dart';

/// Persists push tokens for remote messaging fanout.
class PushTokenService {
  PushTokenService._();

  static final PushTokenService instance = PushTokenService._();

  Future<void> upsertToken({
    required String petId,
    required String token,
    required String platform,
    required String locale,
  }) async {
    if (token.isEmpty) return;

    final supabase = SupabaseClientService.instance;
    if (!supabase.isAvailable) return;

    final hasSession = await supabase.ensureAnonymousSession();
    if (!hasSession) return;

    final client = supabase.client;
    final ownerId = supabase.userId;
    if (client == null || ownerId == null) return;

    try {
      await client.from('fcm_tokens').upsert(
        {
          'owner_id': ownerId,
          'token': token,
          'pet_id': petId,
          'platform': platform,
          'locale': locale,
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'owner_id,token',
      );
    } catch (e) {
      debugPrint('PushTokenService: token upsert failed ($e).');
    }
  }
}
