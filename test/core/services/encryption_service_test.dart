import 'package:flutter_test/flutter_test.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:encrypt/encrypt.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test(
      'deriveKey generates a consistent key from passphrase (deterministic salt)',
      () async {
        final passphrase = 'mysecretpassphrase';

        final key1 = await encryptionService.deriveKey(passphrase);
        final key2 = await encryptionService.deriveKey(passphrase);

        expect(key1.bytes, equals(key2.bytes));
      },
    );

    test(
      'deriveKey generates different keys for different passphrases',
      () async {
        final passphrase1 = 'mysecretpassphrase';
        final passphrase2 = 'anothersecretpassphrase';

        final key1 = await encryptionService.deriveKey(passphrase1);
        final key2 = await encryptionService.deriveKey(passphrase2);

        expect(key1.bytes, isNot(equals(key2.bytes)));
      },
    );

    test('generateDeterministicSalt produces consistent salt', () {
      final passphrase = 'testpassphrase';
      final salt1 = encryptionService.generateDeterministicSalt(passphrase);
      final salt2 = encryptionService.generateDeterministicSalt(passphrase);
      expect(salt1, equals(salt2));
    });

    test(
      'generateDeterministicSalt produces different salt for different passphrase',
      () {
        final passphrase1 = 'testpassphrase1';
        final passphrase2 = 'testpassphrase2';
        final salt1 = encryptionService.generateDeterministicSalt(passphrase1);
        final salt2 = encryptionService.generateDeterministicSalt(passphrase2);
        expect(salt1, isNot(equals(salt2)));
      },
    );

    test('encrypt and decrypt work correctly with valid key and IV', () async {
      final passphrase = 'testpassphrase';
      final key = await encryptionService.deriveKey(passphrase);
      final iv = encryptionService.generateIV();
      final plaintext = 'Hello, Kilo Code!';

      final encrypted = encryptionService.encrypt(plaintext, key, iv);
      final decrypted = encryptionService.decrypt(encrypted, key, iv);

      expect(decrypted, equals(plaintext));
    });

    test('decrypt fails with incorrect key', () async {
      final passphrase1 = 'testpassphrase';
      final passphrase2 = 'wrongpassphrase';
      final key1 = await encryptionService.deriveKey(passphrase1);
      final key2 = await encryptionService.deriveKey(passphrase2);
      final iv = encryptionService.generateIV();
      final plaintext = 'Hello, Kilo Code!';

      final encrypted = encryptionService.encrypt(plaintext, key1, iv);

      expect(
        () => encryptionService.decrypt(encrypted, key2, iv),
        throwsA(anything),
      );
    });

    test('decrypt fails with incorrect IV', () async {
      final passphrase = 'testpassphrase';
      final key = await encryptionService.deriveKey(passphrase);
      final iv1 = encryptionService.generateIV();
      final iv2 = encryptionService.generateIV();
      final plaintext = 'Hello, Kilo Code!';

      final encrypted = encryptionService.encrypt(plaintext, key, iv1);

      final decrypted = encryptionService.decrypt(encrypted, key, iv2);
      expect(decrypted, isNot(equals(plaintext)));
      expect(decrypted, isNotEmpty);
    });

    test('generateIV generates a non-empty IV', () {
      final iv = encryptionService.generateIV();
      expect(iv, isA<IV>());
      expect(iv.bytes, isNotEmpty);
    });
  });
}
