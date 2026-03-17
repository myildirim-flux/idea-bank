import 'package:flutter/material.dart';

class Folder {
  final String id;
  final String name;
  final Color color;
  final int noteCount; // This will be dynamic based on notes in the folder
  final DateTime lastModified;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    this.noteCount = 0,
    required this.lastModified,
  });

  Folder copyWith({
    String? id,
    String? name,
    Color? color,
    int? noteCount,
    DateTime? lastModified,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      noteCount: noteCount ?? this.noteCount,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class Note {
  final String id;
  final String folderId;
  final String? title; // Plaintext title (might be null if note is encrypted)
  final String? body; // Plaintext body (might be null if note is encrypted)
  final String? encryptedTitle; // Encrypted title
  final String? encryptedBody; // Encrypted body
  final String? iv;
  final bool isEncrypted;
  final DateTime createdAt;
  final Color color;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? drawingPreview; // Stores the PNG preview
  final String? strokes; // Stores the raw stroke data as a JSON string
  final bool hasAttachments; // Indicates if the note has attachments
  final DateTime lastModified;

  Note({
    required this.id,
    required this.folderId,
    this.title, // Make nullable
    this.body, // Make nullable
    this.encryptedTitle,
    this.encryptedBody,
    this.iv,
    this.isEncrypted = false,
    required this.createdAt,
    required this.color,
    this.isDeleted = false,
    this.deletedAt,
    this.drawingPreview,
    this.strokes,
    this.hasAttachments = false, // Initialize hasAttachments
    required this.lastModified,
  });

  Note copyWith({
    String? id,
    String? folderId,
    String? title,
    String? body,
    String? encryptedTitle,
    String? encryptedBody,
    String? iv,
    bool? isEncrypted,
    DateTime? createdAt,
    Color? color,
    bool? isDeleted,
    DateTime? deletedAt,
    String? drawingPreview,
    String? strokes,
    bool? hasAttachments, // Add to copyWith
    DateTime? lastModified,
  }) {
    return Note(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      body: body ?? this.body,
      encryptedTitle: encryptedTitle ?? this.encryptedTitle,
      encryptedBody: encryptedBody ?? this.encryptedBody,
      iv: iv ?? this.iv,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      drawingPreview: drawingPreview ?? this.drawingPreview,
      strokes: strokes ?? this.strokes,
      hasAttachments:
          hasAttachments ?? this.hasAttachments, // Update hasAttachments
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
