import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg; // Alias for Key type
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/pointycastle.dart' as pointycastle;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart'; // Explicitly import Ref

part 'encryption_service.g.dart';

@Riverpod(keepAlive: true)
EncryptionService encryptionService(Ref ref) {
  return EncryptionService();
}

/// Top-level function required by compute() — must not be inside a class.
/// Runs PBKDF2-SHA256 with 100,000 iterations and returns the raw key bytes.
Uint8List _pbkdf2Derive(String passphrase) {
  final digest = SHA256Digest();
  final hash = digest.process(Uint8List.fromList(utf8.encode(passphrase)));
  final salt = hash.sublist(0, 16);

  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  final params = pointycastle.Pbkdf2Parameters(salt, 100000, 32);
  pbkdf2.init(params);
  return pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
}

class EncryptionService {
  final FlutterSecureStorage _secureStorage;

  // Allow injecting FlutterSecureStorage for testing
  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _keyStorageKey = 'encryption_key';
  // static const String _saltStorageKey = 'encryption_salt'; // Deprecated

  // Derives a 256-bit (32-byte) key from a passphrase using PBKDF2.
  // Runs on a background isolate via compute() to avoid blocking the UI thread.
  Future<encrypt_pkg.Key> deriveKey(String passphrase) async {
    final keyBytes = await compute(_pbkdf2Derive, passphrase);
    return encrypt_pkg.Key(keyBytes);
  }

  // Encrypts plaintext using AES-256 in CBC mode with a given key and IV.
  encrypt_pkg.Encrypted encrypt(
    String plaintext,
    encrypt_pkg.Key key,
    encrypt_pkg.IV iv,
  ) {
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
    );
    return encrypter.encrypt(plaintext, iv: iv);
  }

  // Decrypts encrypted data using AES-256 in CBC mode with a given key and IV.
  String decrypt(
    encrypt_pkg.Encrypted encrypted,
    encrypt_pkg.Key key,
    encrypt_pkg.IV iv,
  ) {
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
    );
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Encrypts bytes using AES-256 in CBC mode with a given key and IV.
  Uint8List encryptBytes(
    Uint8List data,
    encrypt_pkg.Key key,
    encrypt_pkg.IV iv,
  ) {
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
    );
    return encrypter.encryptBytes(data, iv: iv).bytes;
  }

  // Decrypts bytes using AES-256 in CBC mode with a given key and IV.
  Uint8List decryptBytes(
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

  // Generates a deterministic 16-byte salt from the passphrase using SHA-256.
  Uint8List generateDeterministicSalt(String passphrase) {
    final digest = SHA256Digest();
    final bytes = utf8.encode(passphrase);
    final hash = digest.process(Uint8List.fromList(bytes));
    return hash.sublist(0, 16); // Use first 16 bytes as salt
  }

  // Generates a secure random 16-byte IV.
  encrypt_pkg.IV generateIV() {
    return encrypt_pkg.IV.fromSecureRandom(16); // 16 bytes for IV
  }

  // Saves the encryption key to secure storage.
  Future<void> saveKey(encrypt_pkg.Key key) async {
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(key.bytes),
    );
  }

  // Reads the encryption key from secure storage.
  Future<encrypt_pkg.Key?> readKey() async {
    final String? keyString = await _secureStorage.read(key: _keyStorageKey);
    if (keyString == null) {
      return null;
    }
    return encrypt_pkg.Key(base64Decode(keyString));
  }

  /*
  // Saves the salt to secure storage.
  Future<void> saveSalt(Uint8List salt) async {
    await _secureStorage.write(key: _saltStorageKey, value: base64Encode(salt));
  }

  // Reads the salt from secure storage.
  Future<Uint8List?> readSalt() async {
    final String? saltString = await _secureStorage.read(key: _saltStorageKey);
    if (saltString == null) {
      return null;
    }
    return base64Decode(saltString);
  }
*/
  Future<void> saveSalt(Uint8List salt) async {
    // No-op: Salt is no longer stored
  }

  Future<Uint8List?> readSalt() async {
    return null; // Salt is no longer stored
  }

  // Deletes the stored key and salt.
  Future<void> deleteKeysAndSalt() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _keyStorageKey);
    // await _secureStorage.delete(key: _saltStorageKey);
  }

  // Generates a verification token string: base64(IV):base64(EncryptedToken)
  String generateVerificationToken(encrypt_pkg.Key key) {
    final iv = generateIV();
    final verificationToken = encrypt('IDEA_BANK_VERIFY', key, iv).base64;
    return '${iv.base64}:$verificationToken';
  }
}
