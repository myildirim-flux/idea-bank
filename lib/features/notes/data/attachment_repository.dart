import 'package:sqflite/sqflite.dart';
import 'package:idea_bank/core/services/database_service.dart';
import 'package:idea_bank/features/notes/models/attachment_model.dart';

class AttachmentRepository {
  final DatabaseService _databaseService;

  AttachmentRepository(this._databaseService);

  Future<void> addAttachment(Attachment attachment) async {
    final db = await _databaseService.database;
    // Ensure isSynced is set (defaults to false/0 if not provided in map, but typically models don't have it unless updated)
    // We should ensure the map has is_synced.
    // The model typically maps strict fields. We can add it manually to the map.
    final map = attachment.toMap();
    if (!map.containsKey('is_synced')) {
      map['is_synced'] = 0;
    }

    await db.insert(
      'attachments',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Attachment>> getAttachmentsForNote(String noteId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );

    return List.generate(maps.length, (i) {
      return Attachment.fromMap(maps[i]);
    });
  }

  Future<List<Attachment>> getAllAttachments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('attachments');

    return List.generate(maps.length, (i) {
      return Attachment.fromMap(maps[i]);
    });
  }

  Future<Attachment?> getAttachment(String attachmentId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'id = ?',
      whereArgs: [attachmentId],
    );

    if (maps.isNotEmpty) {
      return Attachment.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final db = await _databaseService.database;
    await db.delete('attachments', where: 'id = ?', whereArgs: [attachmentId]);
  }

  Future<List<Attachment>> getUnsyncedAttachments() async {
    final db = await _databaseService.database;
    // We want attachments where is_synced is 0 or null
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'is_synced = 0 OR is_synced IS NULL',
    );

    return List.generate(maps.length, (i) {
      return Attachment.fromMap(maps[i]);
    });
  }

  Future<void> markAsSynced(String attachmentId) async {
    final db = await _databaseService.database;
    await db.update(
      'attachments',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [attachmentId],
    );
  }
}
