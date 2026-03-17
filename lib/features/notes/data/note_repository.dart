import 'package:flutter/material.dart'; // Import for Color
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:idea_bank/core/constants.dart';

class NoteRepository {
  final DatabaseService _databaseService;

  NoteRepository(this._databaseService);

  Note _fromMap(Map<String, dynamic> map, {bool hasAttachments = false}) {
    return Note(
      id: map['id'],
      folderId: map['folderId'] ?? kAllNotesFolderId,
      title: map['title'],
      body: map['body'],
      encryptedTitle: map['encryptedTitle'],
      encryptedBody: map['encryptedBody'],
      iv: map['iv'],
      isEncrypted: map['isEncrypted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      color: Color(map['color']),
      isDeleted: map['isDeleted'] == 1,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'])
          : null,
      drawingPreview: map['drawingPreview'],
      strokes: map['strokes'],
      hasAttachments: hasAttachments,
      lastModified: DateTime.parse(map['lastModified']),
    );
  }

  Map<String, dynamic> _toMap(Note note) {
    return {
      'id': note.id,
      'folderId': note.folderId,
      'title': note.title,
      'body': note.body,
      'encryptedTitle': note.encryptedTitle,
      'encryptedBody': note.encryptedBody,
      'iv': note.iv,
      'isEncrypted': note.isEncrypted ? 1 : 0,
      'createdAt': note.createdAt.toIso8601String(),
      'lastModified': note.lastModified.toIso8601String(),
      'color': note.color.toARGB32(),
      'isDeleted': note.isDeleted ? 1 : 0,
      'deletedAt': note.deletedAt?.toIso8601String(),
      'drawingPreview': note.drawingPreview,
      'strokes': note.strokes,
    };
  }

  Future<List<Note>> getNotes() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );

    List<Note> notes = [];
    for (var map in maps) {
      final attachmentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM attachments WHERE note_id = ?',
              [map['id']],
            ),
          ) ??
          0;
      notes.add(_fromMap(map, hasAttachments: attachmentCount > 0));
    }
    return notes;
  }

  Future<List<Note>> getNotesInFolder(String folderId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'isDeleted = 0 AND folderId = ?',
      whereArgs: [folderId],
      orderBy: 'createdAt DESC',
    );

    List<Note> notes = [];
    for (var map in maps) {
      final attachmentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM attachments WHERE note_id = ?',
              [map['id']],
            ),
          ) ??
          0;
      notes.add(_fromMap(map, hasAttachments: attachmentCount > 0));
    }
    return notes;
  }

  Future<List<Note>> getTrashedNotes() async {
    final db = await _databaseService.database;
    _cleanUpOldTrashedNotes(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'isDeleted = 1',
      orderBy: 'deletedAt DESC',
    );
    List<Note> notes = [];
    for (var map in maps) {
      final attachmentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM attachments WHERE note_id = ?',
              [map['id']],
            ),
          ) ??
          0;
      notes.add(_fromMap(map, hasAttachments: attachmentCount > 0));
    }
    return notes;
  }

  Future<void> addNote(Note note) async {
    final db = await _databaseService.database;
    await db.insert(
      'notes',
      _toMap(note),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note updatedNote) async {
    final db = await _databaseService.database;
    await db.update(
      'notes',
      _toMap(updatedNote),
      where: 'id = ?',
      whereArgs: [updatedNote.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDeleteNote(String id) async {
    final db = await _databaseService.database;
    await db.update(
      'notes',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreNote(String id) async {
    final db = await _databaseService.database;
    await db.update(
      'notes',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNotePermanently(String id) async {
    final db = await _databaseService.database;
    await db.delete('attachments', where: 'note_id = ?', whereArgs: [id]);
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTrash() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> trashedNoteMaps = await db.query(
      'notes',
      where: 'isDeleted = 1',
    );

    for (var noteMap in trashedNoteMaps) {
      final noteId = noteMap['id'];
      await db.delete('attachments', where: 'note_id = ?', whereArgs: [noteId]);
    }

    await db.delete('notes', where: 'isDeleted = 1');
  }

  Future<void> deleteNotesInFolderPermanently(String folderId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> notesInFolder = await db.query(
      'notes',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );

    for (var noteMap in notesInFolder) {
      final noteId = noteMap['id'];
      await db.delete('attachments', where: 'note_id = ?', whereArgs: [noteId]);
    }

    await db.delete('notes', where: 'folderId = ?', whereArgs: [folderId]);
  }

  Future<bool> hasNotesInFolder(String folderId) async {
    final db = await _databaseService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notes WHERE folderId = ? AND isDeleted = 0',
        [folderId],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<void> _cleanUpOldTrashedNotes(Database db) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final List<Map<String, dynamic>> oldTrashedNoteMaps = await db.query(
      'notes',
      where: 'isDeleted = 1 AND deletedAt < ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );

    for (var noteMap in oldTrashedNoteMaps) {
      final noteId = noteMap['id'];
      await db.delete('attachments', where: 'note_id = ?', whereArgs: [noteId]);
    }
    await db.delete(
      'notes',
      where: 'isDeleted = 1 AND deletedAt < ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );
  }

  Future<void> clearAllNotes() async {
    final db = await _databaseService.database;
    await db.delete('notes');
    await db.delete('attachments');
  }
}
