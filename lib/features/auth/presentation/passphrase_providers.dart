import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:idea_bank/core/services/encryption_service.dart';

/// Provider to hold the user's current passphrase in memory.
/// This should only be set after successful authentication.
final passphraseProvider = StateProvider<String?>((ref) => null);

/// Provider to check if a master key (and thus a passphrase) has been set.
final hasMasterKeyProvider = FutureProvider<bool>((ref) async {
  final encryptionService = ref.watch(encryptionServiceProvider);
  final key = await encryptionService.readKey();
  return key != null;
});

/// Provider to check if passphrase should be recovered from cloud.
/// Returns true if:
/// - No local key exists
/// - User is logged into Appwrite
/// - User has settings stored in cloud (salt + verification token)
final shouldRecoverFromCloudProvider = FutureProvider<bool>((ref) async {
  // Since we use deterministic salt derived from passphrase,
  // we do not need to recover settings/salt from cloud.
  // We simply rely on the user having the correct passphrase.
  return false;
});
