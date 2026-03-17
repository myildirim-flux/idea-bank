import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/api_key/presentation/api_key_providers.dart';

class AiService {
  final Dio _dio;
  final String? _apiKey;

  static bool? _cachedVerificationResult;
  static String? _cachedApiKey;

  AiService(this._dio, this._apiKey);

  bool get isInitialized => _apiKey != null && _apiKey.isNotEmpty;

  Future<String> getCompletion(String prompt) async {
    if (!isInitialized) {
      throw Exception('Gemini API key not set.');
    }

    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

    try {
      final response = await _dio.post(
        url,
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        },
      );

      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get completion from AI: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Gemini API Error: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to get completion from AI: $e');
    }
  }

  Future<bool> verifyApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      debugPrint('AiService: Verification failed (API key is empty).');
      _cachedVerificationResult = false;
      _cachedApiKey = null;
      return false;
    }

    // If the API key is the same and we have a cached result, return it.
    if (_cachedApiKey == apiKey && _cachedVerificationResult != null) {
      debugPrint(
        'AiService: Returning cached verification result for the same API key.',
      );
      return _cachedVerificationResult!;
    }

    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
    debugPrint('AiService: Verifying key with POST request to $url');
    try {
      final response = await _dio.post(
        url,
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'test'},
              ],
            },
          ],
        },
      );
      debugPrint(
        'AiService: Verification response status: ${response.statusCode}',
      );
      debugPrint('AiService: Verification response data: ${response.data}');

      final isValid = response.statusCode == 200;
      _cachedVerificationResult = isValid;
      _cachedApiKey = apiKey;
      return isValid;
    } on DioException catch (e) {
      debugPrint('AiService: Verification failed with DioException.');
      if (e.response != null) {
        debugPrint('DioException response status: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');
      } else {
        debugPrint('DioException error message: ${e.message}');
      }
      _cachedVerificationResult = false;
      _cachedApiKey = apiKey;
      return false;
    } catch (e) {
      debugPrint('AiService: Verification failed with a generic error: $e');
      _cachedVerificationResult = false;
      _cachedApiKey = apiKey;
      return false;
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(
        seconds: 30,
      ), // Increase connection timeout
    ),
  );
});

final aiServiceProvider = Provider<AiService>((ref) {
  final dio = ref.watch(dioProvider);
  final apiKey = ref.watch(apiKeyProvider).value;
  return AiService(dio, apiKey);
});
