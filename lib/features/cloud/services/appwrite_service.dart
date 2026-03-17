import 'package:appwrite/appwrite.dart';
import 'dart:async';

import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:idea_bank/core/env.dart';
import 'package:idea_bank/core/models.dart';

import 'package:idea_bank/features/notes/data/note_repository.dart';
import 'package:idea_bank/features/folders/data/folder_repository.dart';

import 'package:idea_bank/features/notes/data/attachment_repository.dart';
import 'package:idea_bank/features/notes/models/attachment_model.dart'; // Add model import
import 'package:path_provider/path_provider.dart'; // Add path_provider import
import 'dart:io';

class AppwriteService {
  final Client? _sessionClient; // For user authentication
  Timer? _syncTimer;
  Function()? _onDataChanged; // Callback to trigger sync on data changes

  AppwriteService(this._sessionClient, [Client? apiClient]);

  Client? get client => _sessionClient;

  // Modified to check _sessionClient instead of _apiClient
  bool get isCloudEnabled =>
      _sessionClient != null &&
      !(Env.appwriteDatabaseId.isEmpty || Env.appwriteTableId.isEmpty);

  Future<void> syncData(
    NoteRepository noteRepository,
    FolderRepository folderRepository,
    AttachmentRepository attachmentRepository, {
    String? userId,

    // EncryptionService? encryptionService, // No longer needed
  }) async {
    if (!isCloudEnabled) return;
    if (_sessionClient == null) return;

    // Use _sessionClient for database operations (User Session)
    final databases = Databases(_sessionClient);
    final localNotes = await noteRepository.getNotes();
    final localFolders = await folderRepository.getAllFoldersFromDb();

    late final dynamic remoteDocs;
    try {
      remoteDocs = await databases.listDocuments(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.appwriteTableId,
      );
    } on AppwriteException catch (e) {
      debugPrint(
        'AppwriteService: listDocuments failed - code:${e.code} message:${e.message} response:${e.response}',
      );
      if (e.code == 401) {
        debugPrint(
          'AppwriteService: User unauthorized. Please ensure you are logged in.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('AppwriteService: listDocuments unexpected error - $e');
      rethrow;
    }

    debugPrint(
      "Appwrite raw documents: ${remoteDocs.documents.map((d) => d.data).toList()}",
    );

    // Detect notes/folders by the presence of 'type' field.
    final remoteNotes = remoteDocs.documents
        .where((doc) => doc.data != null && doc.data['type'] == 'note')
        .toList();
    final remoteFolders = remoteDocs.documents
        .where((doc) => doc.data != null && doc.data['type'] == 'folder')
        .toList();

    // Sync notes
    await _syncItems<Note>(
      localItems: localNotes,
      remoteItems: remoteNotes,
      localGetter: (item) => item.id,
      remoteGetter: (item) => item.$id,
      localTimestamp: (item) => item.lastModified,
      remoteTimestamp: (item) => DateTime.parse(item.data['lastModified']),
      onLocalNewer: (local, remote) async {
        try {
          await databases.updateDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: remote.$id,
            data: _noteToAppwrite(local),
          );
        } on AppwriteException catch (e) {
          debugPrint(
            'AppwriteService: updateDocument(note) failed - code:${e.code} message:${e.message} response:${e.response}',
          );
          rethrow;
        } catch (e) {
          debugPrint(
            'AppwriteService: updateDocument(note) unexpected error - $e',
          );
          rethrow;
        }
      },
      onRemoteNewer: (local, remote) async {
        debugPrint("onRemoteNewer (note) data: ${remote.data}");
        await noteRepository.updateNote(
          _noteFromAppwrite({...remote.data, 'id': remote.$id}),
        );
      },
      onLocalOnly: (local) async {
        try {
          await databases.createDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: local.id,
            data: _noteToAppwrite(local),
          );
        } on AppwriteException catch (e) {
          debugPrint(
            'AppwriteService: createDocument(note) failed - code:${e.code} message:${e.message} response:${e.response}',
          );
          rethrow;
        } catch (e) {
          debugPrint(
            'AppwriteService: createDocument(note) unexpected error - $e',
          );
          rethrow;
        }
      },
      onRemoteOnly: (remote) async {
        debugPrint("onRemoteOnly (note) data: ${remote.data}");
        await noteRepository.addNote(
          _noteFromAppwrite({...remote.data, 'id': remote.$id}),
        );
      },
    );

    // Sync folders
    await _syncItems<Folder>(
      localItems: localFolders,
      remoteItems: remoteFolders,
      localGetter: (item) => item.id,
      remoteGetter: (item) => item.$id,
      localTimestamp: (item) => item.lastModified,
      remoteTimestamp: (item) => DateTime.parse(item.data['lastModified']),
      onLocalNewer: (local, remote) async {
        try {
          await databases.updateDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: remote.$id,
            data: _folderToAppwrite(local),
          );
        } on AppwriteException catch (e) {
          debugPrint(
            'AppwriteService: updateDocument(folder) failed - code:${e.code} message:${e.message} response:${e.response}',
          );
          rethrow;
        } catch (e) {
          debugPrint(
            'AppwriteService: updateDocument(folder) unexpected error - $e',
          );
          rethrow;
        }
      },
      onRemoteNewer: (local, remote) async {
        await folderRepository.addFolder(
          _folderFromAppwrite({...remote.data, 'id': remote.$id}),
        );
      },
      onLocalOnly: (local) async {
        try {
          await databases.createDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: local.id,
            data: _folderToAppwrite(local),
          );
        } on AppwriteException catch (e) {
          debugPrint(
            'AppwriteService: createDocument(folder) failed - code:${e.code} message:${e.message} response:${e.response}',
          );
          rethrow;
        } catch (e) {
          debugPrint(
            'AppwriteService: createDocument(folder) unexpected error - $e',
          );
          rethrow;
        }
      },
      onRemoteOnly: (remote) async {
        await folderRepository.addFolder(
          _folderFromAppwrite({...remote.data, 'id': remote.$id}),
        );
      },
    );

    // Sync Attachments Metadata
    final localAttachments = await attachmentRepository.getAllAttachments();
    final remoteAttachments = remoteDocs.documents
        .where((doc) => doc.data != null && doc.data['type'] == 'attachment')
        .toList();

    // Helper to get encrypted dir path (lazy loaded)
    String? encryptedDir;
    Future<String> getEncryptedDir() async {
      if (encryptedDir != null) return encryptedDir!;
      final appDocDir = await getApplicationDocumentsDirectory();
      encryptedDir = '${appDocDir.path}/encrypted_attachments';
      final dir = Directory(encryptedDir!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return encryptedDir!;
    }

    await _syncItems<Attachment>(
      localItems: localAttachments,
      remoteItems: remoteAttachments,
      localGetter: (item) => item.id,
      remoteGetter: (item) => item.$id,
      localTimestamp: (item) => item.createdAt,
      remoteTimestamp: (item) =>
          DateTime.parse(item.$createdAt), // Use system $createdAt
      // Note: Attachment doesn't have modification time usually, assuming immutable.
      // Using createdAt for timestamp check.
      onLocalNewer: (local, remote) async {
        // Attachments are immutable mostly. If we really need update:
        // Update metadata only
        try {
          await databases.updateDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: remote.$id,
            data: _attachmentToAppwrite(local),
          );
        } catch (e) {
          debugPrint('AppwriteService: updateDocument(attachment) error - $e');
          // Don't rethrow for metadata update failure on attachment as it's less critical
        }
      },
      onRemoteNewer: (local, remote) async {
        final dir = await getEncryptedDir();
        await attachmentRepository.addAttachment(
          _attachmentFromAppwrite({
            ...remote.data,
            'id': remote.$id,
            'createdAt': remote.$createdAt,
          }, dir),
        );
        await attachmentRepository.markAsSynced(remote.$id);
      },
      onLocalOnly: (local) async {
        try {
          await databases.createDocument(
            databaseId: Env.appwriteDatabaseId,
            collectionId: Env.appwriteTableId,
            documentId: local.id,
            data: _attachmentToAppwrite(local),
          );
        } catch (e) {
          debugPrint('AppwriteService: createDocument(attachment) error - $e');
          // Don't rethrow, maybe limits or something.
        }
      },
      onRemoteOnly: (remote) async {
        final dir = await getEncryptedDir();
        await attachmentRepository.addAttachment(
          _attachmentFromAppwrite({
            ...remote.data,
            'id': remote.$id,
            'createdAt': remote.$createdAt,
          }, dir),
        );
        await attachmentRepository.markAsSynced(remote.$id);
      },
    );

    // Sync pending file uploads (Files that have metadata locally but IS_SYNCED=0)
    // This is distinct from metadata sync.
    await _syncAttachments(attachmentRepository);

    // Sync User Settings (Salt) - REMOVED
  }

  Future<void> _syncAttachments(
    AttachmentRepository attachmentRepository,
  ) async {
    final unsyncedAttachments = await attachmentRepository
        .getUnsyncedAttachments();
    debugPrint(
      'AppwriteService: Found ${unsyncedAttachments.length} unsynced attachments.',
    );

    for (var attachment in unsyncedAttachments) {
      debugPrint('AppwriteService: Uploading attachment ${attachment.id}...');
      final file = File(attachment.localPathEncrypted);
      if (!await file.exists()) {
        debugPrint(
          'AppwriteService: Encrypted file not found at ${attachment.localPathEncrypted}. Skipping.',
        );
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        await uploadAttachment(attachment.id, bytes);
        await attachmentRepository.markAsSynced(attachment.id);
        debugPrint('AppwriteService: Attachment ${attachment.id} synced.');
      } catch (e) {
        debugPrint(
          'AppwriteService: Failed to sync attachment ${attachment.id}: $e',
        );
      }
    }
  }

  Future<void> _syncItems<T>({
    required List<T> localItems,
    required List<dynamic> remoteItems,
    required String Function(T) localGetter,
    required String Function(dynamic) remoteGetter,
    required DateTime Function(T) localTimestamp,
    required DateTime Function(dynamic) remoteTimestamp,
    required Future<void> Function(T, dynamic) onLocalNewer,
    required Future<void> Function(T, dynamic) onRemoteNewer,
    required Future<void> Function(T) onLocalOnly,
    required Future<void> Function(dynamic) onRemoteOnly,
  }) async {
    final localMap = {for (var item in localItems) localGetter(item): item};
    final remoteMap = {for (var item in remoteItems) remoteGetter(item): item};

    for (final localEntry in localMap.entries) {
      final remoteItem = remoteMap[localEntry.key];
      if (remoteItem != null) {
        final localDate = localTimestamp(localEntry.value);
        final remoteDate = remoteTimestamp(remoteItem);
        if (localDate.isAfter(remoteDate)) {
          await onLocalNewer(localEntry.value, remoteItem);
        } else if (remoteDate.isAfter(localDate)) {
          await onRemoteNewer(localEntry.value, remoteItem);
        }
      } else {
        await onLocalOnly(localEntry.value);
      }
    }

    for (final remoteEntry in remoteMap.entries) {
      if (!localMap.containsKey(remoteEntry.key)) {
        await onRemoteOnly(remoteEntry.value);
      }
    }
  }

  Map<String, dynamic> _noteToAppwrite(Note note) {
    return {
      'type': 'note',
      'folderId': note.folderId,
      'encryptedTitle': note.encryptedTitle,
      'encryptedBody': note.encryptedBody,
      'iv': note.iv,
      'isEncrypted': note.isEncrypted,
      'lastModified': note.lastModified.toIso8601String(),
      'color': note.color.toARGB32(),
      'isDeleted': note.isDeleted,
      'deletedAt': note.deletedAt?.toIso8601String(),
      'drawingPreview': note.drawingPreview,
      'strokes': note.strokes,
      'hasAttachments': note.hasAttachments,
    };
  }

  Note _noteFromAppwrite(Map<String, dynamic> data) {
    debugPrint("Data from Appwrite: $data");
    final lastModified = DateTime.parse(data['lastModified']);
    return Note(
      id: data['id'] ?? '',
      folderId: data['folderId'],
      title: null,
      body: null,
      encryptedTitle: data['encryptedTitle'],
      encryptedBody: data['encryptedBody'],
      iv: data['iv'],
      isEncrypted: data['isEncrypted'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : lastModified,
      lastModified: lastModified,
      color: Color(data['color']),
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.parse(data['deletedAt'])
          : null,
      drawingPreview: data['drawingPreview'],
      strokes: data['strokes'] ?? '',
      hasAttachments: data['hasAttachments'] ?? false,
    );
  }

  Map<String, dynamic> _folderToAppwrite(Folder folder) {
    return {
      'type': 'folder',
      'name': folder.name,
      'color': folder.color.toARGB32(),
      'lastModified': folder.lastModified.toIso8601String(),
    };
  }

  Folder _folderFromAppwrite(Map<String, dynamic> data) {
    return Folder(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      color: Color(data['color']),
      lastModified: DateTime.parse(data['lastModified']),
    );
  }

  Map<String, dynamic> _attachmentToAppwrite(Attachment attachment) {
    return {
      'type': 'attachment',
      'noteId': attachment.noteId,
      'originalFilename': attachment.originalFilename,
      'iv': attachment.iv,
      'fileType': attachment.fileType,
      'fileSize': attachment.fileSize,
      // 'createdAt': attachment.createdAt.toIso8601String(), // User uses system $createdAt
    };
  }

  Attachment _attachmentFromAppwrite(
    Map<String, dynamic> data,
    String encryptedDir,
  ) {
    return Attachment(
      id: data['id'] ?? '',
      noteId: data['noteId'] ?? '',
      originalFilename: data['originalFilename'] ?? 'unknown',
      localPathEncrypted: '$encryptedDir/${data['id']}.enc',
      iv: data['iv'] ?? '',
      fileType: data['fileType'],
      fileSize: data['fileSize'],
      createdAt: DateTime.parse(
        data['createdAt'],
      ), // Expects injected $createdAt
    );
  }

  void startAutoSync(
    NoteRepository noteRepository,
    FolderRepository folderRepository,
    AttachmentRepository attachmentRepository,
  ) {
    if (!isCloudEnabled) return;
    _syncTimer?.cancel();
    _onDataChanged = () =>
        syncData(noteRepository, folderRepository, attachmentRepository);
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncData(noteRepository, folderRepository, attachmentRepository);
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _onDataChanged = null;
  }

  void triggerSyncIfEnabled() {
    _onDataChanged?.call();
  }

  Future<void> uploadAttachment(
    String attachmentId,
    Uint8List encryptedBytes,
  ) async {
    if (!isCloudEnabled || _sessionClient == null) return;
    try {
      final storage = Storage(_sessionClient);
      await storage.createFile(
        bucketId: Env.appwriteBucketId,
        fileId: attachmentId,
        file: InputFile.fromBytes(
          bytes: encryptedBytes,
          filename: '$attachmentId.enc',
        ),
      );
      debugPrint(
        'AppwriteService: Attachment $attachmentId uploaded to cloud.',
      );
    } on AppwriteException catch (e) {
      debugPrint(
        'AppwriteService: Error uploading attachment - code:${e.code} message:${e.message} response:${e.response}',
      );
      rethrow; // Rethrow to let caller know it failed
    } catch (e) {
      debugPrint('AppwriteService: Error uploading attachment - $e');
      rethrow; // Rethrow to let caller know it failed
    }
  }

  Future<Uint8List?> downloadAttachment(String attachmentId) async {
    if (!isCloudEnabled || _sessionClient == null) return null;
    try {
      final storage = Storage(_sessionClient);
      final file = await storage.getFileDownload(
        bucketId: Env.appwriteBucketId,
        fileId: attachmentId,
      );
      debugPrint(
        'AppwriteService: Attachment $attachmentId downloaded from cloud.',
      );
      return file;
    } on AppwriteException catch (e) {
      debugPrint(
        'AppwriteService: Error downloading attachment - code:${e.code} message:${e.message} response:${e.response}',
      );
      return null;
    } catch (e) {
      debugPrint('AppwriteService: Error downloading attachment - $e');
      return null;
    }
  }

  Future<void> deleteAttachmentFromCloud(String attachmentId) async {
    if (!isCloudEnabled || _sessionClient == null) return;
    try {
      final storage = Storage(_sessionClient);
      await storage.deleteFile(
        bucketId: Env.appwriteBucketId,
        fileId: attachmentId,
      );
      debugPrint(
        'AppwriteService: Attachment $attachmentId deleted from cloud.',
      );
    } on AppwriteException catch (e) {
      debugPrint(
        'AppwriteService: Error deleting attachment from cloud - code:${e.code} message:${e.message} response:${e.response}',
      );
    } catch (e) {
      debugPrint('AppwriteService: Error deleting attachment from cloud - $e');
    }
  }
}
