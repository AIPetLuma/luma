import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages sensitive secrets (API keys, tokens) in platform-native
/// secure storage (Keychain on iOS, EncryptedSharedPreferences on Android).
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAnthropicApiKey = 'anthropic_api_key';

  /// Read the Anthropic API key, or null if not stored yet.
  static Future<String?> getApiKey() async {
    return _storage.read(key: _keyAnthropicApiKey);
  }

  /// Store the Anthropic API key.
  static Future<void> setApiKey(String key) async {
    await _storage.write(key: _keyAnthropicApiKey, value: key);
  }

  /// Delete stored API key.
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _keyAnthropicApiKey);
  }

  /// Check if an API key is already stored.
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
