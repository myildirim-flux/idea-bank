import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';

void main() {
  group('decryptNote Unit Tests', () {
    late EncryptionService encryptionService;
    late encrypt_pkg.Key key;
    late encrypt_pkg.IV iv;

    setUp(() {
      encryptionService = EncryptionService();
      key = encrypt_pkg.Key.fromUtf8(
        '12345678901234567890123456789012',
      ); // 32-byte key
      iv = encryptionService.generateIV();
    });

    test('decryptNote returns original note if missing encrypted fields', () {
      final note = Note(
        id: '1',
        folderId: 'all',
        title: 'Plaintext Title',
        body: 'Plaintext Body',
        createdAt: DateTime.now(),
        color: Colors.white,
        lastModified: DateTime.now(),
      );

      final result = decryptNote(note, key, encryptionService);
      expect(result.title, equals('Plaintext Title'));
      expect(result.body, equals('Plaintext Body'));
    });

    test('decryptNote successfully decrypts encrypted title and body', () {
      final originalTitle = 'Secret Idea';
      final originalBody = 'This is confidential information.';

      final encryptedTitle = encryptionService.encrypt(originalTitle, key, iv);
      final encryptedBody = encryptionService.encrypt(originalBody, key, iv);

      final note = Note(
        id: '2',
        folderId: 'all',
        encryptedTitle: encryptedTitle.base64,
        encryptedBody: encryptedBody.base64,
        iv: iv.base64,
        isEncrypted: true,
        createdAt: DateTime.now(),
        color: Colors.blue,
        lastModified: DateTime.now(),
      );

      final decrypted = decryptNote(note, key, encryptionService);

      expect(decrypted.title, equals(originalTitle));
      expect(decrypted.body, equals(originalBody));
    });

    test(
      'decryptNote handles decryption failure gracefully with placeholder',
      () {
        final wrongKey = encrypt_pkg.Key.fromUtf8(
          '99999999999999999999999999999999',
        );

        final encryptedTitle = encryptionService.encrypt(
          'Secret Title',
          key,
          iv,
        );
        final encryptedBody = encryptionService.encrypt('Secret Body', key, iv);

        final note = Note(
          id: '3',
          folderId: 'all',
          encryptedTitle: encryptedTitle.base64,
          encryptedBody: encryptedBody.base64,
          iv: iv.base64,
          isEncrypted: true,
          createdAt: DateTime.now(),
          color: Colors.red,
          lastModified: DateTime.now(),
        );

        final result = decryptNote(note, wrongKey, encryptionService);

        expect(result.title, equals('[Decryption Failed]'));
        expect(result.body, contains('This note could not be decrypted'));
      },
    );
  });
}
