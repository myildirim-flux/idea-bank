import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/notes/data/note_repository.dart';
import 'package:riverpod/riverpod.dart'; // Explicitly import Ref
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg; // For Key and IV types
import 'package:idea_bank/core/services/database_service.dart'; // For DatabaseService
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart'; // For appwriteServiceProvider

part 'note_providers.g.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Helper function to safely decrypt a note.
/// If decryption fails, returns a note with placeholder text indicating the error.
Note decryptNote(
  Note note,
  encrypt_pkg.Key key,
  EncryptionService encryptionService,
) {
  // Check if note has encrypted data (all notes should be encrypted now)
  if (note.encryptedTitle == null ||
      note.encryptedBody == null ||
      note.iv == null) {
    return note; // Return as-is if no encrypted data (shouldn't happen)
  }

  try {
    final iv = encrypt_pkg.IV.fromBase64(note.iv!);
    final decryptedTitle = encryptionService.decrypt(
      encrypt_pkg.Encrypted.fromBase64(note.encryptedTitle!),
      key,
      iv,
    );
    final decryptedBody = encryptionService.decrypt(
      encrypt_pkg.Encrypted.fromBase64(note.encryptedBody!),
      key,
      iv,
    );

    // Decrypt drawing data if present
    String? decryptedDrawingPreview;
    String? decryptedStrokes;
    if (note.drawingPreview != null && note.drawingPreview!.isNotEmpty) {
      try {
        decryptedDrawingPreview = encryptionService.decrypt(
          encrypt_pkg.Encrypted.fromBase64(note.drawingPreview!),
          key,
          iv,
        );
      } catch (e) {
        debugPrint('Failed to decrypt drawing preview for note ${note.id}: $e');
      }
    }
    if (note.strokes != null && note.strokes!.isNotEmpty) {
      try {
        decryptedStrokes = encryptionService.decrypt(
          encrypt_pkg.Encrypted.fromBase64(note.strokes!),
          key,
          iv,
        );
      } catch (e) {
        debugPrint('Failed to decrypt strokes for note ${note.id}: $e');
      }
    }

    return note.copyWith(
      title: decryptedTitle,
      body: decryptedBody,
      drawingPreview: decryptedDrawingPreview,
      strokes: decryptedStrokes,
    );
  } catch (e) {
    debugPrint('Decryption failed for note ${note.id}: $e');
    return note.copyWith(
      title: '[Decryption Failed]',
      body:
          'This note could not be decrypted. It may have been encrypted with a different passphrase or the data may be corrupted.',
    );
  }
}

@Riverpod(keepAlive: true)
NoteRepository noteRepository(Ref ref) {
  return NoteRepository(ref.read(databaseServiceProvider));
}

@riverpod
Future<List<Note>> folderNotes(Ref ref) async {
  final selectedFolderId = ref.watch(selectedFolderIdProvider);
  final allNotes = await ref.watch(
    noteProvider.future,
  ); // Watch the NoteNotifier state and await its future

  List<Note> notesToReturn;
  if (selectedFolderId == 'all_notes') {
    notesToReturn = allNotes;
  } else {
    notesToReturn = allNotes
        .where((note) => note.folderId == selectedFolderId)
        .toList();
  }
  notesToReturn.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return notesToReturn;
}

@riverpod
Future<List<Note>> allNotes(Ref ref) async {
  final allNotes = await ref.watch(
    noteProvider.future,
  ); // Watch the NoteNotifier state and await its future
  final searchQuery = ref.watch(searchQueryProvider);
  List<Note> filteredNotes = allNotes;

  if (searchQuery.isNotEmpty) {
    filteredNotes = filteredNotes.where((note) {
      final queryLower = searchQuery.toLowerCase();
      return (note.title ?? '').toLowerCase().contains(queryLower) ||
          (note.body ?? '').toLowerCase().contains(queryLower);
    }).toList();
  }
  filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filteredNotes;
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
bool showSearchResults(Ref ref) {
  return ref.watch(searchQueryProvider).isNotEmpty;
}

@riverpod
Future<List<Note>> notes(Ref ref) async {
  final showSearch = ref.watch(showSearchResultsProvider);
  if (showSearch) {
    return ref.watch(allNotesProvider.future);
  } else {
    return ref.watch(folderNotesProvider.future);
  }
}

@riverpod
Future<List<Note>> notesInFolder(Ref ref, String folderId) async {
  final noteRepo = ref.watch(noteRepositoryProvider);
  final notes = await noteRepo.getNotesInFolder(folderId);

  // Decrypt all notes before returning
  final encryptionService = ref.read(encryptionServiceProvider);
  final key = await encryptionService.readKey();

  if (key == null) {
    return notes; // Return encrypted notes if no key available
  }

  // Decrypt each note
  final decryptedNotes = notes.map((note) {
    if (note.isEncrypted) {
      return decryptNote(note, key, encryptionService);
    }
    return note;
  }).toList();

  return decryptedNotes;
}

@riverpod
Future<List<Note>> trashedNotes(Ref ref) async {
  final noteRepo = ref.watch(noteRepositoryProvider);
  final trashedNotes = await noteRepo.getTrashedNotes();

  // Decrypt all notes before sorting and returning
  final encryptionService = ref.read(encryptionServiceProvider);
  final key = await encryptionService.readKey();

  List<Note> decryptedNotes = trashedNotes;
  if (key != null) {
    decryptedNotes = trashedNotes.map((note) {
      if (note.isEncrypted) {
        return decryptNote(note, key, encryptionService);
      }
      return note;
    }).toList();
  }

  decryptedNotes.sort((Note a, Note b) {
    if (a.deletedAt == null && b.deletedAt == null) return 0;
    if (a.deletedAt == null) return 1; // Nulls last
    if (b.deletedAt == null) return -1; // Nulls last
    return b.deletedAt!.compareTo(a.deletedAt!);
  });
  return decryptedNotes;
}

final decryptionErrorProvider = StateProvider<bool>((ref) => false);

@riverpod
class NoteNotifier extends _$NoteNotifier {
  @override
  Future<List<Note>> build() async {
    final notes = await ref.watch(noteRepositoryProvider).getNotes();

    // Decrypt all notes before returning
    final encryptionService = ref.read(encryptionServiceProvider);
    final key = await encryptionService.readKey();

    if (key == null) {
      return notes; // Return encrypted notes if no key available
    }

    // Decrypt each note
    final decryptedNotes = notes.map((note) {
      if (note.isEncrypted) {
        return decryptNote(note, key, encryptionService);
      }
      return note;
    }).toList();

    return decryptedNotes;
  }

  Future<void> addNote(Note note) async {
    final encryptionService = ref.read(encryptionServiceProvider);
    final noteRepository = ref.watch(noteRepositoryProvider);

    final storedKey = await encryptionService.readKey();
    if (storedKey == null) {
      throw Exception(
        'Encryption key not available. Please set up passphrase first.',
      );
    }

    final iv = encryptionService.generateIV();
    final key = storedKey; // Use the stored master key

    final encryptedTitle = encryptionService.encrypt(note.title!, key, iv);
    final encryptedBody = encryptionService.encrypt(note.body!, key, iv);

    // Encrypt drawing data if present
    String? encryptedDrawingPreview;
    String? encryptedStrokes;
    if (note.drawingPreview != null && note.drawingPreview!.isNotEmpty) {
      final encryptedDrawing = encryptionService.encrypt(
        note.drawingPreview!,
        key,
        iv,
      );
      encryptedDrawingPreview = encryptedDrawing.base64;
    }
    if (note.strokes != null && note.strokes!.isNotEmpty) {
      final encryptedStrokesData = encryptionService.encrypt(
        note.strokes!,
        key,
        iv,
      );
      encryptedStrokes = encryptedStrokesData.base64;
    }

    final encryptedNote = note.copyWith(
      title: null, // Clear plaintext title
      body: null, // Clear plaintext body
      encryptedTitle: encryptedTitle.base64,
      encryptedBody: encryptedBody.base64,
      drawingPreview: encryptedDrawingPreview, // Store encrypted drawing
      strokes: encryptedStrokes, // Store encrypted strokes
      iv: iv.base64,
      isEncrypted: true,
    );
    await noteRepository.addNote(encryptedNote);
    state = AsyncData(await noteRepository.getNotes());
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> updateNote(Note updatedNote) async {
    final encryptionService = ref.read(encryptionServiceProvider);
    final noteRepository = ref.watch(noteRepositoryProvider);

    final storedKey = await encryptionService.readKey();
    if (storedKey == null) {
      throw Exception(
        'Encryption key not available. Please set up passphrase first.',
      );
    }

    encrypt_pkg.IV iv;
    encrypt_pkg.Key key;

    // Reuse existing iv if available, otherwise generate new one
    if (updatedNote.iv != null) {
      iv = encrypt_pkg.IV.fromBase64(updatedNote.iv!);
      key = storedKey; // Use the stored master key
    } else {
      iv = encryptionService.generateIV();
      key = storedKey; // Use the stored master key
    }

    final encryptedTitle = encryptionService.encrypt(
      updatedNote.title!,
      key,
      iv,
    );
    final encryptedBody = encryptionService.encrypt(updatedNote.body!, key, iv);

    // Encrypt drawing data if present
    String? encryptedDrawingPreview;
    String? encryptedStrokes;
    if (updatedNote.drawingPreview != null &&
        updatedNote.drawingPreview!.isNotEmpty) {
      final encryptedDrawing = encryptionService.encrypt(
        updatedNote.drawingPreview!,
        key,
        iv,
      );
      encryptedDrawingPreview = encryptedDrawing.base64;
    }
    if (updatedNote.strokes != null && updatedNote.strokes!.isNotEmpty) {
      final encryptedStrokesData = encryptionService.encrypt(
        updatedNote.strokes!,
        key,
        iv,
      );
      encryptedStrokes = encryptedStrokesData.base64;
    }

    final encryptedNote = updatedNote.copyWith(
      title: null,
      body: null,
      encryptedTitle: encryptedTitle.base64,
      encryptedBody: encryptedBody.base64,
      drawingPreview: encryptedDrawingPreview, // Store encrypted drawing
      strokes: encryptedStrokes, // Store encrypted strokes
      iv: iv.base64,
      isEncrypted: true,
    );
    await noteRepository.updateNote(encryptedNote);
    state = AsyncData(await noteRepository.getNotes());
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> softDeleteNote(String id) async {
    await ref.watch(noteRepositoryProvider).softDeleteNote(id);
    state = AsyncData(await ref.watch(noteRepositoryProvider).getNotes());
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> restoreNote(String id) async {
    await ref.watch(noteRepositoryProvider).restoreNote(id);
    state = AsyncData(await ref.watch(noteRepositoryProvider).getNotes());
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> deleteNotePermanently(String id) async {
    await ref.watch(noteRepositoryProvider).deleteNotePermanently(id);
    state = AsyncData(await ref.watch(noteRepositoryProvider).getNotes());
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> clearTrash() async {
    await ref.watch(noteRepositoryProvider).clearTrash();
    state = AsyncData(await ref.watch(noteRepositoryProvider).getNotes());
    ref.invalidate(trashedNotesProvider);
    ref.invalidate(foldersProvider);

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }
}
