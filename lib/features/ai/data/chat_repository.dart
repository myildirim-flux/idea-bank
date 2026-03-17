import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:idea_bank/core/services/database_service.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/auth/presentation/passphrase_providers.dart';
import 'package:idea_bank/features/ai/models/chat_message.dart';
import 'package:idea_bank/features/ai/models/chat_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref, {String? noteId}) {
  final passphrase = ref.watch(passphraseProvider);
  return ChatRepository(
    ref.watch(databaseServiceProvider),
    ref.watch(encryptionServiceProvider),
    passphrase,
    noteId,
  );
}

class ChatRepository {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  final String? _passphrase;
  final Uuid _uuid = const Uuid();

  ChatRepository(
    this._databaseService,
    this._encryptionService,
    this._passphrase,
    this._noteId,
  );

  final String? _noteId;

  Future<List<ChatSession>> getSessions() async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps;
    if (_noteId != null) {
      maps = await db.query(
        'chat_sessions',
        where: 'noteId = ?',
        whereArgs: [_noteId],
        orderBy: 'createdAt DESC',
      );
    } else {
      maps = await db.query(
        'chat_sessions',
        where: 'noteId IS NULL',
        orderBy: 'createdAt DESC',
      );
    }
    return maps.map((map) => ChatSession.fromJson(map)).toList();
  }

  Future<ChatSession> createSession({String? title}) async {
    final db = await _databaseService.database;
    final id = _uuid.v4();
    final session = ChatSession(
      id: id,
      title: title ?? 'New Chat',
      createdAt: DateTime.now(),
      noteId: _noteId,
    );
    await db.insert('chat_sessions', session.toJson());
    return session;
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    final key = await _getDecryptionKey();

    if (key == null) {
      // If there's no key, we can't decrypt anything.
      // We'll return the messages, but encrypted ones will have empty content.
      return maps.map((map) {
        final message = ChatMessage.fromJson(map);
        if (message.isEncrypted) {
          return message.copyWith(content: '[Encrypted]');
        }
        return message;
      }).toList();
    }

    return maps.map((map) {
      final message = ChatMessage.fromJson(map);
      if (message.isEncrypted &&
          message.encryptedContent != null &&
          message.iv != null) {
        try {
          final iv = encrypt.IV.fromBase64(message.iv!);
          final encrypted = encrypt.Encrypted.fromBase64(
            message.encryptedContent!,
          );
          final decryptedContent = _encryptionService.decrypt(
            encrypted,
            key,
            iv,
          );
          return message.copyWith(content: decryptedContent);
        } catch (e) {
          // If decryption fails, show error placeholder
          return message.copyWith(
            content: '[Decryption Failed] Message could not be decrypted.',
          );
        }
      }
      return message;
    }).toList();
  }

  Future<void> addMessage(ChatMessage message) async {
    final db = await _databaseService.database;
    final key = await _getDecryptionKey();
    ChatMessage messageToSave = message;

    if (key != null && message.content.isNotEmpty) {
      final iv = _encryptionService.generateIV();
      final encrypted = _encryptionService.encrypt(message.content, key, iv);

      messageToSave = message.copyWith(
        isEncrypted: true,
        encryptedContent: encrypted.base64,
        iv: iv.base64,
        content: '', // Clear the plaintext content
      );
    }

    await db.insert('chat_messages', messageToSave.toJson());
  }

  Future<void> clearMessages(String sessionId) async {
    final db = await _databaseService.database;
    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await _databaseService.database;
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
    // Corresponding messages will be deleted by CASCADE constraint
  }

  Future<encrypt.Key?> _getDecryptionKey() async {
    if (_passphrase == null) {
      return null;
    }
    return _encryptionService.deriveKey(_passphrase);
  }
}
