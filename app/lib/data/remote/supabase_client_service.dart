import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase client bootstrap and auth session management.
class SupabaseClientService {
  SupabaseClient? _client;

  SupabaseClientService._();

  static final SupabaseClientService instance = SupabaseClientService._();

  bool get isAvailable => _client != null;

  SupabaseClient? get client => _client;

  String? get userId => _client?.auth.currentUser?.id;

  Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    if (_client != null) return;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('SupabaseClientService: missing credentials — disabled.');
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _client = Supabase.instance.client;
    } catch (e) {
      try {
        _client = Supabase.instance.client;
        debugPrint('SupabaseClientService: using existing initialized client.');
      } catch (_) {
        debugPrint('SupabaseClientService: init failed ($e) — disabled.');
        return;
      }
    }

    await ensureAnonymousSession();
  }

  Future<bool> ensureAnonymousSession() async {
    final client = _client;
    if (client == null) return false;

    if (client.auth.currentSession != null) {
      return true;
    }

    try {
      final response = await client.auth.signInAnonymously();
      return response.session != null || client.auth.currentSession != null;
    } catch (e) {
      debugPrint('SupabaseClientService: anonymous sign-in failed ($e).');
      return false;
    }
  }
}
