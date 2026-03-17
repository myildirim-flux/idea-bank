import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';

import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/notes/models/attachment_model.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';

import 'package:encrypt/encrypt.dart' as encrypt_pkg; // Import Encrypted and IV

import 'package:idea_bank/features/notes/data/attachment_repository.dart';

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(
    ref.read(attachmentRepositoryProvider),
    ref.read(encryptionServiceProvider),
    ref.read(appwriteServiceProvider), // Add Appwrite service
    ref, // Pass ref to check auto-sync state
  );
});

class AttachmentService {
  final AttachmentRepository _attachmentRepository;
  final EncryptionService _encryptionService;
  final dynamic _appwriteService; // AppwriteService
  final Ref _ref; // To check auto-sync state
  final Uuid _uuid;

  // Maximum file size: 10MB
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  AttachmentService(
    this._attachmentRepository,
    this._encryptionService,
    this._appwriteService,
    this._ref,
  ) : _uuid = const Uuid();

  /// Gets the directory for storing encrypted attachments
  Future<Directory> _getEncryptedAttachmentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDocDir.path}/encrypted_attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Encrypts bytes using AES-CBC
  Uint8List _encryptBytes(
    Uint8List data,
    encrypt_pkg.Key key,
    encrypt_pkg.IV iv,
  ) {
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
    );
    return encrypter.encryptBytes(data, iv: iv).bytes;
  }

  /// Decrypts bytes using AES-CBC
  Uint8List _decryptBytes(
    Uint8List encryptedData,
    encrypt_pkg.Key key,
    encrypt_pkg.IV iv,
  ) {
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
    );
    return Uint8List.fromList(
      encrypter.decryptBytes(encrypt_pkg.Encrypted(encryptedData), iv: iv),
    );
  }

  /// Adds an encrypted attachment to a note
  Future<Attachment?> addAttachment(String noteId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        throw Exception(
          'File size exceeds 10MB limit. Please select a smaller file.',
        );
      }

      final key = await _encryptionService.readKey();
      final iv = _encryptionService.generateIV();
      if (key == null) {
        throw Exception("Encryption key not found.");
      }

      // Read and encrypt file contents
      final originalBytes = await file.readAsBytes();
      final encryptedBytes = _encryptBytes(originalBytes, key, iv);

      // Save encrypted file
      final attachmentsDir = await _getEncryptedAttachmentsDirectory();
      final encryptedFileName = '${_uuid.v4()}.enc';
      final encryptedFile = File('${attachmentsDir.path}/$encryptedFileName');
      await encryptedFile.writeAsBytes(encryptedBytes);

      final mimeType = lookupMimeType(file.path);

      // Initially synced=false (0), handled by repository default if not present, but let's be explicit
      final attachment = Attachment(
        id: _uuid.v4(),
        noteId: noteId,
        originalFilename: result.files.single.name,
        localPathEncrypted:
            encryptedFile.path, // Now stores path to encrypted file
        iv: iv.base64,
        fileType: mimeType,
        fileSize: originalBytes.length, // Original file size
        createdAt: DateTime.now(),
      );

      // We need to add is_synced to the model or handle it in repo.
      // Since model doesn't have it, we rely on repo logic or map usage in repo.
      await _attachmentRepository.addAttachment(attachment);

      // Upload encrypted file to cloud if cloud is enabled (regardless of auto-sync)
      // This ensures attachments are backed up immediately.
      if (_appwriteService.isCloudEnabled) {
        try {
          await _appwriteService.uploadAttachment(
            attachment.id,
            encryptedBytes,
          );
          debugPrint('Attachment ${attachment.id} uploaded to cloud');
          // Mark as synced
          await _attachmentRepository.markAsSynced(attachment.id);
        } catch (e) {
          debugPrint('Failed to upload attachment to cloud: $e');
          // Continue even if cloud upload fails - file is saved locally.
          // It remains is_synced=0 in DB.
        }
      }

      return attachment;
    }
    return null;
  }

  /// Gets all attachments for a specific note
  Future<List<Attachment>> getAttachmentsForNote(String noteId) async {
    return _attachmentRepository.getAttachmentsForNote(noteId);
  }

  /// Deletes an attachment and its encrypted file
  Future<void> deleteAttachment(String attachmentId) async {
    final attachment = await _attachmentRepository.getAttachment(attachmentId);

    if (attachment != null) {
      try {
        // Delete the encrypted file
        final encryptedFile = File(attachment.localPathEncrypted);
        if (await encryptedFile.exists()) {
          await encryptedFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting encrypted file: $e');
        // Continue to delete database entry even if file deletion fails
      }

      // Delete from cloud only if auto-sync is enabled
      // Note: If we really want to ensure cloud deletion, we might want to track "deleted_at" and sync deletions too.
      // For now, sticking to existing logic but using repo.
      final isAutoSyncEnabled = _ref.read(autoSyncProvider);
      if (isAutoSyncEnabled) {
        try {
          await _appwriteService.deleteAttachmentFromCloud(attachmentId);
          debugPrint('Attachment $attachmentId deleted from cloud');
        } catch (e) {
          debugPrint('Failed to delete attachment from cloud: $e');
          // Continue even if cloud deletion fails
        }
      } else {
        // If offline, we might want to queue deletion?
        // Current scope is reliable UPLOAD. Deletion reliability is a separate concern but valid.
        // Leaving as is per scope.
      }

      await _attachmentRepository.deleteAttachment(attachmentId);
    }
  }

  /// Opens an attachment by decrypting it and writing to a temporary location
  Future<void> openAttachment(Attachment attachment) async {
    final key = await _encryptionService.readKey();
    if (key == null) {
      throw Exception("Encryption key not found.");
    }

    try {
      final encryptedFile = File(attachment.localPathEncrypted);
      Uint8List encryptedBytes;

      // Check if file exists locally, if not try to download from cloud (only if auto-sync is enabled)
      if (await encryptedFile.exists()) {
        encryptedBytes = await encryptedFile.readAsBytes();
      } else {
        final isCloudEnabled = _appwriteService.isCloudEnabled;
        if (!isCloudEnabled) {
          throw Exception(
            'Attachment file not found locally and cloud is disabled.',
          );
        }

        debugPrint(
          'Attachment file not found locally, downloading from cloud...',
        );
        final downloadedBytes = await _appwriteService.downloadAttachment(
          attachment.id,
        );
        if (downloadedBytes == null) {
          throw Exception('Attachment not found locally or in cloud storage.');
        }
        // Save to local storage
        await encryptedFile.writeAsBytes(downloadedBytes);
        encryptedBytes = downloadedBytes;
      }

      final iv = encrypt_pkg.IV.fromBase64(attachment.iv);
      final decryptedBytes = _decryptBytes(encryptedBytes, key, iv);

      // Write to temp file with original extension
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${attachment.originalFilename}');
      await tempFile.writeAsBytes(decryptedBytes);

      await OpenFilex.open(tempFile.path);

      // Clean up temp file after 5 minutes
      Future.delayed(Duration(minutes: 5), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } catch (e) {
      debugPrint('Error opening attachment: $e');
      throw Exception(
        "Failed to open file. It might be corrupted or permissions are missing.",
      );
    }
  }
}
