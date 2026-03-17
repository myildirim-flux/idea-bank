import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:idea_bank/features/api_key/services/api_key_service.dart';
import 'package:idea_bank/features/ai/services/ai_service.dart';

enum ApiKeyStatus { unknown, invalid, valid, notSet }

final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, AsyncValue<String?>>((ref) {
      final apiKeyService = ref.watch(apiKeyServiceProvider);
      return ApiKeyNotifier(apiKeyService);
    });

class ApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  final ApiKeyService _apiKeyService;

  ApiKeyNotifier(this._apiKeyService) : super(const AsyncValue.loading()) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    // Check if the notifier has been disposed
    if (!mounted) return;

    state = const AsyncValue.loading();
    debugPrint('ApiKeyNotifier: Loading API key...');
    try {
      final apiKey = await _apiKeyService.getApiKey();
      if (!mounted) return;
      state = AsyncValue.data(apiKey);
    } catch (e, st) {
      debugPrint('ApiKeyNotifier: Error loading API key: $e');
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    await _apiKeyService.saveApiKey(apiKey);
    // Reload the key from the service to ensure the state is in sync
    if (mounted) {
      await _loadApiKey();
    }
  }

  Future<void> deleteApiKey() async {
    await _apiKeyService.deleteApiKey();
    if (mounted) {
      state = const AsyncValue.data(null);
    }
  }
}

final apiKeyVerificationFutureProvider = FutureProvider<ApiKeyStatus>((
  ref,
) async {
  // Create local instances to avoid dependency-based re-execution
  final apiKeyService = ref.read(apiKeyServiceProvider);
  final dio = ref.read(dioProvider);

  final apiKey = await apiKeyService.getApiKey();

  if (apiKey == null || apiKey.isEmpty) {
    return ApiKeyStatus.notSet;
  }

  // Use a local, single-use AiService for verification
  final aiService = AiService(dio, apiKey);
  final isValid = await aiService.verifyApiKey(apiKey);

  return isValid ? ApiKeyStatus.valid : ApiKeyStatus.invalid;
});

final apiKeyStatusProvider =
    StateNotifierProvider<ApiKeyStatusNotifier, ApiKeyStatus>((ref) {
      return ApiKeyStatusNotifier(ref);
    });

class ApiKeyStatusNotifier extends StateNotifier<ApiKeyStatus> {
  final Ref _ref;

  ApiKeyStatusNotifier(this._ref) : super(ApiKeyStatus.unknown) {
    _ref.listen<AsyncValue<ApiKeyStatus>>(apiKeyVerificationFutureProvider, (
      previous,
      next,
    ) {
      void applyState() {
        if (!mounted) return;
        next.when(
          data: (status) => state = status,
          loading: () => state = ApiKeyStatus.unknown,
          error: (err, stack) {
            debugPrint('Error verifying API key: $err');
            state = ApiKeyStatus.invalid;
          },
        );
      }

      // Defer state updates to avoid modifying a provider during widget tree build
      Future.microtask(applyState);
    }, fireImmediately: true);
  }

  Future<bool> checkAndSaveApiKey(String apiKey) async {
    // When saving a new key, we must re-verify it.
    final dio = _ref.read(dioProvider);
    final aiService = AiService(
      dio,
      apiKey,
    ); // Use a local instance for verification
    final isValid = await aiService.verifyApiKey(apiKey);

    if (isValid) {
      await _ref.read(apiKeyProvider.notifier).saveApiKey(apiKey);
      _ref.invalidate(
        apiKeyVerificationFutureProvider,
      ); // Invalidate to force re-run with the new key
    }

    // Manually update the state for immediate UI feedback
    state = isValid ? ApiKeyStatus.valid : ApiKeyStatus.invalid;

    return isValid;
  }
}
