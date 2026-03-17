import 'package:flutter/material.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/core/services/database_service.dart';
import 'package:idea_bank/features/folders/data/folder_repository.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; // Explicitly import Ref
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart'; // For appwriteServiceProvider

part 'folder_providers.g.dart';

@Riverpod(keepAlive: true)
Future<FolderRepository> folderRepository(Ref ref) async {
  final noteRepository = ref.watch(noteRepositoryProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  final folderRepo = FolderRepository(noteRepository, databaseService, ref);
  await folderRepo.init(); // Initialize the repository to load folders from DB
  return folderRepo;
}

@Riverpod(keepAlive: true)
class SelectedFolderId extends _$SelectedFolderId {
  @override
  String build() {
    return kAllNotesFolderId; // Default to "All Notes"
  }

  void setSelectedFolder(String folderId) {
    state = folderId;
  }
}

@riverpod
class Folders extends _$Folders {
  @override
  Future<List<Folder>> build() async {
    final folderRepo = await ref.watch(folderRepositoryProvider.future);
    final notesRepo = ref.watch(noteRepositoryProvider);

    final existingFolders = folderRepo.getFolders();

    final List<Folder> allFolders = [];

    // Add "All Notes" folder if it doesn't exist
    if (!existingFolders.any((folder) => folder.id == kAllNotesFolderId)) {
      final allNotesCount = (await notesRepo.getNotes()).length;
      allFolders.add(
        Folder(
          id: kAllNotesFolderId,
          name: 'All Ideas',
          color: Colors.grey, // Default color for "All Notes"
          noteCount: allNotesCount, // Count all notes
          lastModified: DateTime.now(),
        ),
      );
    }

    // Update note counts for each existing folder
    for (final folder in existingFolders) {
      final noteCount = (await notesRepo.getNotesInFolder(folder.id)).length;
      allFolders.add(folder.copyWith(noteCount: noteCount));
    }
    return allFolders.cast<Folder>();
  }

  Future<void> addFolder(Folder folder) async {
    final folderRepo = await ref.read(folderRepositoryProvider.future);
    await folderRepo.addFolder(folder);
    ref.invalidateSelf();

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }

  Future<void> deleteFolder(String folderId) async {
    final folderRepo = await ref.read(folderRepositoryProvider.future);
    await folderRepo.deleteFolder(folderId);
    ref.invalidateSelf();

    // Trigger immediate sync if auto-sync is enabled
    ref.read(appwriteServiceProvider).triggerSyncIfEnabled();
  }
}
