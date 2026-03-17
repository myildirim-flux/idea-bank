import 'package:flutter/material.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/core/services/database_service.dart';
import 'package:idea_bank/features/notes/data/note_repository.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite
import 'package:riverpod/riverpod.dart'; // Import Ref
import 'package:idea_bank/features/notes/presentation/note_providers.dart'; // Import note_providers

class FolderRepository {
  final NoteRepository _noteRepository;
  final DatabaseService _databaseService;
  final Ref _ref; // Add Ref here
  List<Folder> _folders = [];

  FolderRepository(
    this._noteRepository,
    this._databaseService,
    this._ref,
  ); // Update constructor

  Future<void> init() async {
    _folders = await getAllFoldersFromDb();
  }

  List<Folder> getFolders() {
    return _folders;
  }

  Future<void> addFolder(Folder folder) async {
    final db = await _databaseService.database;
    await db.insert('folders', {
      'id': folder.id,
      'name': folder.name,
      'color': folder.color.toARGB32(),
      'lastModified': folder.lastModified.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Check if folder already exists in memory before adding
    final existingIndex = _folders.indexWhere((f) => f.id == folder.id);
    if (existingIndex != -1) {
      // Update existing folder in memory
      _folders[existingIndex] = folder;
    } else {
      // Add new folder to in-memory list
      _folders.add(folder);
    }
  }

  Future<List<Folder>> getAllFoldersFromDb() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) {
      return Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        color: Color(maps[i]['color']),
        lastModified: DateTime.parse(maps[i]['lastModified']),
      );
    });
  }

  Future<bool> hasNotesInFolder(String folderId) async {
    return (await _noteRepository.getNotesInFolder(folderId)).isNotEmpty;
  }

  Future<void> deleteFolder(String folderId) async {
    final db = await _databaseService.database;
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    await _noteRepository.deleteNotesInFolderPermanently(folderId);
    _ref.invalidate(noteProvider);
    _ref.invalidate(folderNotesProvider);
    _folders.removeWhere(
      (folder) => folder.id == folderId,
    ); // Remove from in-memory list
  }

  Future<void> clearAllFolders() async {
    final db = await _databaseService.database;
    await db.delete('folders');
    _folders.clear(); // Clear in-memory list
  }
}
