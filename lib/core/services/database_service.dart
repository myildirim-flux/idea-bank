import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_service.g.dart';

@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'idea_bank.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        folderId TEXT,
        title TEXT,
        body TEXT,
        encryptedTitle TEXT,
        encryptedBody TEXT,
        iv TEXT,
        isEncrypted INTEGER,
        createdAt TEXT,
        lastModified TEXT,
        color INTEGER,
        isDeleted INTEGER,
        deletedAt TEXT,
        drawingPreview TEXT,
        strokes TEXT,
        hasAttachments INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE folders(
        id TEXT PRIMARY KEY,
        name TEXT,
        color INTEGER,
        lastModified TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attachments(
        id TEXT PRIMARY KEY,
        note_id TEXT,
        original_filename TEXT NOT NULL,
        local_path_encrypted TEXT NOT NULL,
        iv TEXT NOT NULL,
        file_type TEXT,
        file_size INTEGER,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages(
        id TEXT PRIMARY KEY,
        session_id TEXT,
        content TEXT,
        encryptedContent TEXT,
        salt TEXT,
        iv TEXT,
        isEncrypted INTEGER,
        type TEXT,
        timestamp TEXT,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_sessions(
        id TEXT PRIMARY KEY,
        title TEXT,
        createdAt TEXT,
        noteId TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE chat_sessions(
          id TEXT PRIMARY KEY,
          title TEXT,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE chat_messages(
          id TEXT PRIMARY KEY,
          session_id TEXT,
          content TEXT,
          encryptedContent TEXT,
          salt TEXT,
          iv TEXT,
          isEncrypted INTEGER,
          type TEXT,
          timestamp TEXT,
          FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN lastModified TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN hasAttachments INTEGER');
      await db.execute('ALTER TABLE folders ADD COLUMN lastModified TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE chat_sessions ADD COLUMN noteId TEXT');
    }
    if (oldVersion < 5) {
      // Remove salt column from notes table
      // SQLite doesn't support DROP COLUMN, so we need to recreate the table
      await db.execute('''
        CREATE TABLE notes_new(
          id TEXT PRIMARY KEY,
          folderId TEXT,
          title TEXT,
          body TEXT,
          encryptedTitle TEXT,
          encryptedBody TEXT,
          iv TEXT,
          isEncrypted INTEGER,
          createdAt TEXT,
          lastModified TEXT,
          color INTEGER,
          isDeleted INTEGER,
          deletedAt TEXT,
          drawingPreview TEXT,
          strokes TEXT,
          hasAttachments INTEGER
        )
      ''');

      // Copy data from old table to new table (excluding salt column)
      await db.execute('''
        INSERT INTO notes_new (id, folderId, title, body, encryptedTitle, encryptedBody, 
                               iv, isEncrypted, createdAt, lastModified, color, isDeleted, 
                               deletedAt, drawingPreview, strokes, hasAttachments)
        SELECT id, folderId, title, body, encryptedTitle, encryptedBody, 
               iv, isEncrypted, createdAt, lastModified, color, isDeleted, 
               deletedAt, drawingPreview, strokes, hasAttachments
        FROM notes
      ''');

      // Drop old table
      await db.execute('DROP TABLE notes');

      // Rename new table to notes
      await db.execute('ALTER TABLE notes_new RENAME TO notes');
    }
    if (oldVersion < 6) {
      // Version 6: Add is_synced column to attachments table
      try {
        await db.execute(
          'ALTER TABLE attachments ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Ignore if column already exists (in case of partial migration)
        debugPrint('Error adding is_synced column: \$e');
      }
    }
  }
}
