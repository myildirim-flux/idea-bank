import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/services/database_service.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';
import 'package:idea_bank/features/cloud/services/appwrite_service.dart';

final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService(
    ref.read(databaseServiceProvider),
    ref.read(encryptionServiceProvider),
    ref.read(appwriteServiceProvider),
  );
});

/// Service that handles re-encryption of all data when passphrase changes.
/// This ensures all encrypted notes, chat messages, and attachments are re-encrypted with the new key.
class MigrationService {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  final AppwriteService _appwriteService;

  MigrationService(
    this._databaseService,
    this._encryptionService,
    this._appwriteService,
  );

  /// Re-encrypts all encrypted data from oldKey to newKey.
  /// Returns the number of items successfully re-encrypted.
  Future<int> reEncryptAllData(
    encrypt_pkg.Key oldKey,
    encrypt_pkg.Key newKey, {
    Function(String status, double progress)? onProgress,
  }) async {
    int successCount = 0;

    // 1. Re-encrypt all notes
    onProgress?.call('Re-encrypting notes...', 0.1);
    successCount += await _reEncryptNotes(oldKey, newKey);

    // 2. Re-encrypt all chat messages
    onProgress?.call('Re-encrypting chat messages...', 0.3);
    successCount += await _reEncryptChatMessages(oldKey, newKey);

    // 3. Re-encrypt all attachments
    // This will update progress from 0.4 to 1.0 internally
    successCount += await _reEncryptAttachments(
      oldKey,
      newKey,
      onProgress: (status, progress) {
        // Map attachment progress (0.0-1.0) to overall progress (0.4-1.0)
        final overallProgress = 0.4 + (progress * 0.6);
        onProgress?.call(status, overallProgress);
      },
    );

    return successCount;
  }

  /// Re-encrypts all encrypted notes.
  Future<int> _reEncryptNotes(
    encrypt_pkg.Key oldKey,
    encrypt_pkg.Key newKey,
  ) async {
    int successCount = 0;
    final db = await _databaseService.database;

    // Get all encrypted notes directly from database
    final List<Map<String, dynamic>> noteMaps = await db.query(
      'notes',
      where: 'isEncrypted = 1',
    );

    for (final noteMap in noteMaps) {
      try {
        final noteId = noteMap['id'] as String;
        final encryptedTitle = noteMap['encryptedTitle'] as String?;
        final encryptedBody = noteMap['encryptedBody'] as String?;
        final ivBase64 = noteMap['iv'] as String?;

        if (encryptedTitle == null ||
            encryptedBody == null ||
            ivBase64 == null) {
          debugPrint(
            'MigrationService: Skipping note $noteId - missing encrypted data',
          );
          continue;
        }

        final oldIv = encrypt_pkg.IV.fromBase64(ivBase64);

        // Decrypt with old key
        final decryptedTitle = _encryptionService.decrypt(
          encrypt_pkg.Encrypted.fromBase64(encryptedTitle),
          oldKey,
          oldIv,
        );
        final decryptedBody = _encryptionService.decrypt(
          encrypt_pkg.Encrypted.fromBase64(encryptedBody),
          oldKey,
          oldIv,
        );

        // Re-encrypt with new key and new IV
        final newIv = _encryptionService.generateIV();
        final newEncryptedTitle = _encryptionService.encrypt(
          decryptedTitle,
          newKey,
          newIv,
        );
        final newEncryptedBody = _encryptionService.encrypt(
          decryptedBody,
          newKey,
          newIv,
        );

        // Update note in database
        await db.update(
          'notes',
          {
            'encryptedTitle': newEncryptedTitle.base64,
            'encryptedBody': newEncryptedBody.base64,
            'iv': newIv.base64,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [noteId],
        );

        successCount++;
        debugPrint('MigrationService: Re-encrypted note $noteId');
      } catch (e) {
        debugPrint(
          'MigrationService: Failed to re-encrypt note ${noteMap['id']}: $e',
        );
        // Continue with other notes even if one fails
      }
    }

    debugPrint('MigrationService: Re-encrypted $successCount notes');
    return successCount;
  }

  /// Re-encrypts all encrypted chat messages.
  Future<int> _reEncryptChatMessages(
    encrypt_pkg.Key oldKey,
    encrypt_pkg.Key newKey,
  ) async {
    int successCount = 0;
    final db = await _databaseService.database;

    // Get all encrypted chat messages directly from database
    final List<Map<String, dynamic>> messageMaps = await db.query(
      'chat_messages',
      where: 'isEncrypted = 1',
    );

    for (final messageMap in messageMaps) {
      try {
        final messageId = messageMap['id'] as String;
        final encryptedContent = messageMap['encryptedContent'] as String?;
        final ivBase64 = messageMap['iv'] as String?;

        if (encryptedContent == null || ivBase64 == null) {
          debugPrint(
            'MigrationService: Skipping message $messageId - missing encrypted data',
          );
          continue;
        }

        final oldIv = encrypt_pkg.IV.fromBase64(ivBase64);

        // Decrypt with old key
        final decryptedContent = _encryptionService.decrypt(
          encrypt_pkg.Encrypted.fromBase64(encryptedContent),
          oldKey,
          oldIv,
        );

        // Re-encrypt with new key and new IV
        final newIv = _encryptionService.generateIV();
        final newEncryptedContent = _encryptionService.encrypt(
          decryptedContent,
          newKey,
          newIv,
        );

        // Update message in database
        await db.update(
          'chat_messages',
          {'encryptedContent': newEncryptedContent.base64, 'iv': newIv.base64},
          where: 'id = ?',
          whereArgs: [messageId],
        );

        successCount++;
      } catch (e) {
        debugPrint(
          'MigrationService: Failed to re-encrypt message ${messageMap['id']}: $e',
        );
        // Continue with other messages even if one fails
      }
    }

    debugPrint('MigrationService: Re-encrypted $successCount chat messages');
    return successCount;
  }

  /// Re-encrypts all attachments.
  Future<int> _reEncryptAttachments(
    encrypt_pkg.Key oldKey,
    encrypt_pkg.Key newKey, {
    Function(String status, double progress)? onProgress,
  }) async {
    int successCount = 0;
    final db = await _databaseService.database;

    // Get all attachments directly from database
    final List<Map<String, dynamic>> attachmentMaps = await db.query(
      'attachments',
    );

    if (attachmentMaps.isEmpty) return 0;

    int current = 0;
    final total = attachmentMaps.length;

    for (final attachmentMap in attachmentMaps) {
      current++;
      try {
        final attachmentId = attachmentMap['id'] as String;
        final localPathEncrypted =
            attachmentMap['localPathEncrypted'] as String;
        final ivBase64 = attachmentMap['iv'] as String;
        final originalFilename = attachmentMap['originalFilename'] as String;

        onProgress?.call(
          'Securing attachment ($current/$total):\n$originalFilename',
          current / total,
        );

        final oldIv = encrypt_pkg.IV.fromBase64(ivBase64);
        final file = File(localPathEncrypted);

        if (!await file.exists()) {
          debugPrint(
            'MigrationService: Skipping attachment $attachmentId - file missing',
          );
          continue;
        }

        // 1. Read and Decrypt with old key
        final encryptedBytes = await file.readAsBytes();
        final decryptedBytes = _encryptionService.decryptBytes(
          encryptedBytes,
          oldKey,
          oldIv,
        );

        // 2. Re-encrypt with new key and new IV
        final newIv = _encryptionService.generateIV();
        final newEncryptedBytes = _encryptionService.encryptBytes(
          decryptedBytes,
          newKey,
          newIv,
        );

        // 3. Save new encrypted file (overwrite existing)
        await file.writeAsBytes(newEncryptedBytes);

        // 4. Update database record with new IV
        await db.update(
          'attachments',
          {
            'iv': newIv.base64,
            // localPathEncrypted stays the same
          },
          where: 'id = ?',
          whereArgs: [attachmentId],
        );

        // 5. Cloud Sync (Delete old, Upload new)
        if (_appwriteService.isCloudEnabled) {
          onProgress?.call(
            'Uploading to secure cloud ($current/$total):\n$originalFilename',
            current / total,
          );

          // We don't wait for delete to finish before uploading to save time.
          // Appwrite storage uses fileId.
          await _appwriteService.deleteAttachmentFromCloud(attachmentId);
          await _appwriteService.uploadAttachment(
            attachmentId,
            newEncryptedBytes,
          );
        }

        successCount++;
        debugPrint('MigrationService: Re-encrypted attachment $attachmentId');
      } catch (e) {
        debugPrint(
          'MigrationService: Failed to re-encrypt attachment ${attachmentMap['id']}: $e',
        );
        // Continue with other attachments
      }
    }

    debugPrint('MigrationService: Re-encrypted $successCount attachments');
    return successCount;
  }
}
