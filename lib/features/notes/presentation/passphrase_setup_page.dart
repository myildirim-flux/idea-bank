import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/services/encryption_service.dart';
import 'package:idea_bank/core/services/migration_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg; // Alias for Key type

import 'package:idea_bank/home_page.dart';

import 'package:idea_bank/features/auth/presentation/passphrase_providers.dart';
import 'package:idea_bank/features/auth/presentation/widgets/security_progress_dialog.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';

class PassphraseSetupPage extends ConsumerStatefulWidget {
  final bool isChangePassphrase;
  const PassphraseSetupPage({super.key, this.isChangePassphrase = false});

  @override
  ConsumerState<PassphraseSetupPage> createState() =>
      _PassphraseSetupPageState();
}

class _PassphraseSetupPageState extends ConsumerState<PassphraseSetupPage> {
  // Use encrypt_pkg.Key for the Key type to resolve ambiguity
  final TextEditingController _oldPassphraseController =
      TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _confirmPassphraseController =
      TextEditingController();
  final StreamController<Map<String, dynamic>> _migrationProgressController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPassphraseController.dispose();
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    _migrationProgressController.close();
    super.dispose();
  }

  Future<void> _setupPassphrase() async {
    // Dismiss the keyboard immediately so it doesn't leave a black area
    // during the route transition to HomePage.
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final oldPassphrase = _oldPassphraseController.text;
    final passphrase = _passphraseController.text;
    final confirmPassphrase = _confirmPassphraseController.text;

    if (passphrase.isEmpty || confirmPassphrase.isEmpty) {
      setState(() {
        _errorMessage = 'Password and confirmation cannot be empty.';
        _isLoading = false;
      });
      return;
    }

    if (passphrase != confirmPassphrase) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    try {
      final encryptionService = ref.read(encryptionServiceProvider);

      // Show the loading dialog immediately so the user sees feedback before
      // any expensive key derivation (100k PBKDF2 iterations) begins.
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    widget.isChangePassphrase
                        ? 'Updating your password...'
                        : 'Securing your ideas...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Setting up encryption. This may take a moment.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      encrypt_pkg.Key? oldKey;
      if (widget.isChangePassphrase) {
        // Verify old passphrase (100k iterations – dialog is already visible)
        final storedKey = await encryptionService.readKey();

        if (storedKey == null) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _errorMessage = 'No existing password found.';
            _isLoading = false;
          });
          return;
        }

        final derivedOldKey = await encryptionService.deriveKey(oldPassphrase);
        if (derivedOldKey.base64 != storedKey.base64) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _errorMessage = 'Incorrect old password.';
            _isLoading = false;
          });
          return;
        }

        // Store the old key for re-encryption
        oldKey = storedKey;
      }

      // Generate master key using deterministic salt (internal to deriveKey)
      final encrypt_pkg.Key masterKey = await encryptionService.deriveKey(
        passphrase,
      );

      // If changing passphrase, re-encrypt all data before saving new key
      if (widget.isChangePassphrase && oldKey != null) {
        final migrationService = ref.read(migrationServiceProvider);

        // Close the outer loading dialog before showing the detailed progress dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show security progress dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                // Determine status and progress from the migration service callback
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _migrationProgressController.stream,
                  initialData: {
                    'status': 'Preparing to secure data...',
                    'progress': 0.0,
                  },
                  builder: (context, snapshot) {
                    final data = snapshot.data!;
                    return SecurityProgressDialog(
                      status: data['status'] as String,
                      progress: data['progress'] as double,
                    );
                  },
                );
              },
            ),
          );
        }

        // Perform migration with progress updates
        await migrationService.reEncryptAllData(
          oldKey,
          masterKey,
          onProgress: (status, progress) {
            _migrationProgressController.add({
              'status': status,
              'progress': progress,
            });
          },
        );

        // Close the dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Data is now locally re-encrypted with new key.
        // Sync metadata (Folder names, Note titles/bodies) to cloud if enabled.
        // Attachments are handled inside migrationService.
        // Guard with its own try/catch: a cloud sync failure (e.g. user not
        // logged in, 401) must NOT surface as a password-change error.
        final appwriteService = ref.read(appwriteServiceProvider);
        if (appwriteService.isCloudEnabled) {
          try {
            final noteRepo = ref.read(noteRepositoryProvider);
            final folderRepo = await ref.read(folderRepositoryProvider.future);
            await appwriteService.syncData(
              noteRepo,
              folderRepo,
              ref.read(attachmentRepositoryProvider),
            );
          } catch (syncError) {
            // Log silently – cloud sync is best-effort after a local password
            // change. The password itself was updated successfully.
            debugPrint('Cloud sync after password change failed: $syncError');
          }
        }
      }

      // Save the master key securely (locally)
      await encryptionService.saveKey(masterKey);

      // Set the passphrase provider so we don't have to ask again in this session
      ref.read(passphraseProvider.notifier).state = passphrase;

      if (!mounted) {
        return;
      }
      // Close the loading dialog (shown for both initial setup and change-password)
      Navigator.of(context, rootNavigator: true).pop();
      // If it's a change passphrase operation, just pop.
      // If it's initial setup, pushReplacement to HomePage.
      if (widget.isChangePassphrase) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ), // Assuming HomePage is the main page after setup
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error setting up passphrase: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error setting up passphrase: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isChangePassphrase
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // App icon for branding
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                widget.isChangePassphrase
                    ? 'Change Password'
                    : 'Secure Your Ideas',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isChangePassphrase
                    ? 'Create a new secure password'
                    : 'Create a password to encrypt your ideas',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Old passphrase field (only for change)
              if (widget.isChangePassphrase) ...[
                TextField(
                  controller: _oldPassphraseController,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.blueGrey700.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.blueGrey700.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New passphrase field
              TextField(
                controller: _passphraseController,
                obscureText: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.blueGrey700.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.blueGrey700.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm passphrase field
              TextField(
                controller: _confirmPassphraseController,
                obscureText: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.blueGrey700.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.blueGrey700.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Submit button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setupPassphrase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isChangePassphrase
                                  ? Icons.sync_lock_rounded
                                  : Icons.lock_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isChangePassphrase
                                  ? 'Update Password'
                                  : 'Secure My Ideas',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
