import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages sensitive secrets (API keys, tokens) in platform-native
/// secure storage (Keychain on iOS, EncryptedSharedPreferences on Android).
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyLlmApiKey = 'llm_api_key';
  static const _legacyAnthropicApiKey = 'anthropic_api_key';

  /// Read the LLM API key, or null if not stored yet.
  static Future<String?> getApiKey() async {
    try {
      final current = await _storage.read(key: _keyLlmApiKey);
      if (current != null && current.isNotEmpty) return current;
      return await _storage.read(key: _legacyAnthropicApiKey);
    } catch (e) {
      debugPrint('SecureStorage read skipped: $e');
      return null;
    }
  }

  /// Store the LLM API key.
  static Future<void> setApiKey(String key) async {
    try {
      await _storage.write(key: _keyLlmApiKey, value: key);
    } catch (e) {
      debugPrint('SecureStorage write skipped: $e');
    }
  }

  /// Delete stored API key.
  static Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _keyLlmApiKey);
      await _storage.delete(key: _legacyAnthropicApiKey);
    } catch (e) {
      debugPrint('SecureStorage delete skipped: $e');
    }
  }

  /// Check if an API key is already stored.
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
