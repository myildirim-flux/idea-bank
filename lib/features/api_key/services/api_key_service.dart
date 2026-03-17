import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiKeyService {
  final FlutterSecureStorage _secureStorage;
  static const _apiKeyStorageKey = 'gemini_api_key';

  ApiKeyService(this._secureStorage);

  Future<void> saveApiKey(String apiKey) async {
    debugPrint('ApiKeyService: Writing key to secure storage...');
    try {
      await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
      debugPrint('ApiKeyService: Successfully wrote key.');
    } catch (e) {
      debugPrint('ApiKeyService: ERROR writing to secure storage: $e');
    }
  }

  Future<String?> getApiKey() async {
    debugPrint('ApiKeyService: Reading key from secure storage...');
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      return apiKey;
    } catch (e) {
      debugPrint('ApiKeyService: ERROR reading from secure storage: $e');
      return null;
    }
  }

  Future<void> deleteApiKey() async {
    debugPrint('ApiKeyService: Deleting key from secure storage...');
    try {
      await _secureStorage.delete(key: _apiKeyStorageKey);
      debugPrint('ApiKeyService: Successfully deleted key.');
    } catch (e) {
      debugPrint('ApiKeyService: ERROR deleting from secure storage: $e');
    }
  }

  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiKeyServiceProvider = Provider<ApiKeyService>((ref) {
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return ApiKeyService(secureStorage);
});