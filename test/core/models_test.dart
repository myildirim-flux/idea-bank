import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_bank/core/models.dart';

void main() {
  group('Folder Model Tests', () {
    final now = DateTime.now();

    test('Folder initializes with default noteCount of 0', () {
      final folder = Folder(
        id: 'folder-1',
        name: 'Work',
        color: Colors.blue,
        lastModified: now,
      );

      expect(folder.id, equals('folder-1'));
      expect(folder.name, equals('Work'));
      expect(folder.color, equals(Colors.blue));
      expect(folder.noteCount, equals(0));
      expect(folder.lastModified, equals(now));
    });

    test('Folder copyWith updates selected fields correctly', () {
      final folder = Folder(
        id: 'folder-1',
        name: 'Work',
        color: Colors.blue,
        noteCount: 5,
        lastModified: now,
      );

      final updatedFolder = folder.copyWith(name: 'Personal', noteCount: 10);

      expect(updatedFolder.id, equals('folder-1'));
      expect(updatedFolder.name, equals('Personal'));
      expect(updatedFolder.color, equals(Colors.blue));
      expect(updatedFolder.noteCount, equals(10));
      expect(updatedFolder.lastModified, equals(now));
    });
  });

  group('Note Model Tests', () {
    final now = DateTime.now();

    test('Note initializes with correct default values', () {
      final note = Note(
        id: 'note-1',
        folderId: 'folder-1',
        title: 'Sample Note',
        body: 'Sample Body Content',
        createdAt: now,
        color: Colors.yellow,
        lastModified: now,
      );

      expect(note.id, equals('note-1'));
      expect(note.folderId, equals('folder-1'));
      expect(note.title, equals('Sample Note'));
      expect(note.body, equals('Sample Body Content'));
      expect(note.isEncrypted, isFalse);
      expect(note.isDeleted, isFalse);
      expect(note.hasAttachments, isFalse);
      expect(note.color, equals(Colors.yellow));
      expect(note.encryptedTitle, isNull);
      expect(note.encryptedBody, isNull);
    });

    test('Note copyWith updates fields properly', () {
      final note = Note(
        id: 'note-1',
        folderId: 'folder-1',
        title: 'Original Title',
        body: 'Original Body',
        createdAt: now,
        color: Colors.yellow,
        lastModified: now,
      );

      final updatedNote = note.copyWith(
        title: 'Updated Title',
        isEncrypted: true,
        encryptedTitle: 'enc_title',
        encryptedBody: 'enc_body',
        iv: 'iv_str',
      );

      expect(updatedNote.id, equals('note-1'));
      expect(updatedNote.title, equals('Updated Title'));
      expect(updatedNote.body, equals('Original Body'));
      expect(updatedNote.isEncrypted, isTrue);
      expect(updatedNote.encryptedTitle, equals('enc_title'));
      expect(updatedNote.encryptedBody, equals('enc_body'));
      expect(updatedNote.iv, equals('iv_str'));
    });

    test('Note copyWith handles soft deletion status change', () {
      final note = Note(
        id: 'note-2',
        folderId: 'folder-1',
        title: 'Trash Test',
        body: 'Body',
        createdAt: now,
        color: Colors.red,
        lastModified: now,
      );

      final deletedAt = DateTime.now();
      final deletedNote = note.copyWith(isDeleted: true, deletedAt: deletedAt);

      expect(deletedNote.isDeleted, isTrue);
      expect(deletedNote.deletedAt, equals(deletedAt));
    });
  });
}
