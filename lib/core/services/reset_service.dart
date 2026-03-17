import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/auth/presentation/auth_providers.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/api_key/services/api_key_service.dart';
import 'package:idea_bank/features/api_key/presentation/api_key_providers.dart';

part 'reset_service.g.dart';

@Riverpod(keepAlive: true)
ResetService resetService(Ref ref) {
  return ResetService(ref);
}

class ResetService {
  final Ref _ref;

  ResetService(this._ref);

  Future<void> resetAppData() async {
    final encryptionService = _ref.read(encryptionServiceProvider);
    final noteRepository = _ref.read(noteRepositoryProvider);
    final folderRepository = await _ref.read(folderRepositoryProvider.future);
    final apiKeyService = _ref.read(apiKeyServiceProvider);
    final authService = _ref.read(authServiceProvider);

    // Logout user to ensure clean state and force re-login for salt recovery
    await authService.logout();
    _ref.read(authStatusProvider.notifier).state = AuthStatus.loggedOut;

    // Delete API key FIRST before invalidating providers
    await apiKeyService.deleteApiKey();

    // Clear data
    await encryptionService.deleteKeysAndSalt();
    noteRepository.clearAllNotes();
    await folderRepository.clearAllFolders();

    // Invalidate Riverpod providers AFTER deleting API key to avoid using disposed notifiers
    _ref.invalidate(noteProvider);
    _ref.invalidate(foldersProvider);
    _ref.invalidate(selectedFolderIdProvider);
    _ref.invalidate(decryptionErrorProvider);
    _ref.invalidate(searchQueryProvider);
    _ref.invalidate(trashedNotesProvider); // Invalidate trashed notes as well
    _ref.invalidate(apiKeyProvider); // Invalidate API key provider
    _ref.invalidate(apiKeyStatusProvider); // Invalidate API key status provider
  }
}
