import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/features/api_key/services/api_key_service.dart';

import 'package:idea_bank/features/auth/presentation/passphrase_providers.dart';

import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/notes/presentation/passphrase_setup_page.dart';
import 'package:idea_bank/home_page.dart';

class PassphraseAuthenticationPage extends ConsumerStatefulWidget {
  const PassphraseAuthenticationPage({super.key});

  @override
  ConsumerState<PassphraseAuthenticationPage> createState() =>
      _PassphraseAuthenticationPageState();
}

class _PassphraseAuthenticationPageState
    extends ConsumerState<PassphraseAuthenticationPage> {
  final TextEditingController _passphraseController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    // Dismiss the keyboard immediately so it doesn't leave a black area
    // during the route transition to HomePage.
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty.';
        _isLoading = false;
      });
      return;
    }

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final storedKey = await encryptionService.readKey();
      if (storedKey == null) {
        // If local key is missing, try to regenerate it from passphrase
        // This handles cases where key might have been deleted but app data exists
        // Or simple re-authentication if we don't store key persistently in some future design

        // deriveKey always returns key
        // Check if this key can decrypt a known value?
        // Since we don't have a known value check here easily without creating one,
        // we technically trust the passphrase in deterministic mode if we don't have a stored hash to verify against.
        // BUT, the original logic had 'storedKey' which is the key.
        // In deterministic world, 'storedKey' IS the derived key from the stored passphrase.. wait.
        // We authenticate by generating the key and comparing it to the 'storedKey' (which is the verified key).
        // If 'storedKey' is null, it means the user hasn't set up the app or local storage is wiped.

        // If storedKey is null, we can't authenticate against it.
        setState(() {
          _errorMessage = 'No passphrase set. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      final derivedKey = await encryptionService.deriveKey(passphrase);

      if (derivedKey.base64 == storedKey.base64) {
        // Authentication successful
        ref.read(passphraseProvider.notifier).state = passphrase;

        // Invalidate note provider to force re-decryption with correct key
        ref.invalidate(noteProvider);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect password.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showResetConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: This action cannot be undone!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Resetting the app will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            BulletPoint('All your ideas and vaults'),
            BulletPoint('All attachments'),
            BulletPoint('Your password'),
            BulletPoint('Cached data and settings'),
            SizedBox(height: 16),
            Text(
              'You will be able to set a new password after reset.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performReset();
            },
            child: const Text('Reset App', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // Get references before reset
      final encryptionService = ref.read(encryptionServiceProvider);
      final noteRepository = ref.read(noteRepositoryProvider);
      final folderRepository = await ref.read(folderRepositoryProvider.future);
      final apiKeyService = ref.read(apiKeyServiceProvider);

      await encryptionService.deleteKeysAndSalt();
      await noteRepository.clearAllNotes();
      await folderRepository.clearAllFolders();
      await apiKeyService.deleteApiKey();

      if (!mounted) return;

      // Navigate to passphrase setup page and clear all routes
      // This ensures we start fresh without disposed providers
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const PassphraseSetupPage(isChangePassphrase: false),
        ),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during reset: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App icon
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                // App title
                const Text(
                  'Idea Bank',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ideas, securely encrypted',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Passphrase input field
                TextField(
                  controller: _passphraseController,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(
                      Icons.key_rounded,
                      color: AppColors.textSecondary,
                    ),
                    errorText: _errorMessage,
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.blueGrey700.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.blueGrey700.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  onSubmitted: (_) => _authenticate(),
                ),
                const SizedBox(height: 24),

                // Unlock button with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Unlock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reset button
                TextButton(
                  onPressed: _isLoading ? null : _showResetConfirmationDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Forgot password? Reset App',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to display bullet points in the reset dialog
class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
