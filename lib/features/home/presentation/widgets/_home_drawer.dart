import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/services/reset_service.dart';

import 'package:idea_bank/features/notes/presentation/passphrase_setup_page.dart'
    as passphrase_setup;
import 'package:idea_bank/features/notes/presentation/trash_bin_page.dart';
import 'package:idea_bank/features/auth/presentation/auth_providers.dart';
import 'package:idea_bank/features/ai/presentation/ai_chat_page.dart';
import 'package:idea_bank/features/api_key/presentation/api_key_providers.dart';
import 'package:idea_bank/features/api_key/presentation/widgets/api_key_dialog.dart';
import 'package:idea_bank/features/auth/presentation/widgets/login_dialog.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({
    required this.hasPassphrase,
    required this.rootContext,
    super.key,
  });

  final bool hasPassphrase;
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyStatus = ref.watch(apiKeyStatusProvider);
    final authStatus = ref.watch(authStatusProvider);
    final autoSync = ref.watch(autoSyncProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final isCloudEnabled = ref.watch(appwriteServiceProvider).isCloudEnabled;

    return Drawer(
      child: Column(
        // Use Column to enable Spacer
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your secure vault',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: Text(hasPassphrase ? 'Change Password' : 'Set Password'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => passphrase_setup.PassphraseSetupPage(
                    isChangePassphrase: hasPassphrase,
                  ),
                ), // Use alias here
              );
            },
          ),
          const Divider(), // Added separator
          ListTile(
            leading: Icon(
              Icons.key_rounded,
              color: _getApiKeyIconColor(apiKeyStatus),
            ),
            title: const Text('API Key'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const ApiKeyDialog(),
              );
            },
          ),
          const Divider(), // Added separator
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline_rounded),
            title: const Text('AI Chat'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatPage(noteId: null),
                ),
              );
            },
          ),
          const Divider(), // Added separator
          ExpansionTile(
            leading: Icon(
              Icons.cloud_queue_rounded,
              color: _getCloudIconColor(isCloudEnabled, authStatus),
            ),
            title: Text(
              'Cloud Sync',
              style: TextStyle(color: isCloudEnabled ? null : Colors.grey),
            ),
            children: <Widget>[
              ListTile(
                enabled: isCloudEnabled,
                leading: const Icon(Icons.login_rounded),
                title: Text(
                  authStatus == AuthStatus.loggedIn ? 'Logout' : 'Login',
                ),
                onTap: !isCloudEnabled
                    ? null
                    : () async {
                        if (authStatus == AuthStatus.loggedIn) {
                          ref.read(authStatusProvider.notifier).state =
                              AuthStatus.loading;
                          await ref.read(authServiceProvider).logout();
                          ref.read(authStatusProvider.notifier).state =
                              AuthStatus.loggedOut;
                        } else {
                          if (ref.context.mounted) {
                            showDialog(
                              context: ref.context,
                              builder: (context) => const LoginDialog(),
                            );
                          }
                        }
                      },
              ),
              ListTile(
                enabled: isCloudEnabled && authStatus == AuthStatus.loggedIn,
                leading: syncStatus == 'Syncing...'
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.sync_rounded),
                title: Text(
                  isCloudEnabled
                      ? (authStatus == AuthStatus.loggedIn
                            ? syncStatus
                            : 'Login required')
                      : 'Disabled',
                ),
                onTap: !(isCloudEnabled && authStatus == AuthStatus.loggedIn)
                    ? null
                    : () async {
                        ref.read(syncStatusProvider.notifier).state =
                            'Syncing...';
                        try {
                          await ref
                              .read(appwriteServiceProvider)
                              .syncData(
                                ref.read(noteRepositoryProvider),
                                await ref.read(folderRepositoryProvider.future),
                                ref.read(attachmentRepositoryProvider),
                                userId:
                                    (await ref
                                            .read(authServiceProvider)
                                            .getUser())
                                        ?.$id,
                                // encryptionService: ref.read(
                                //   encryptionServiceProvider,
                                // ),
                              );

                          // Invalidate providers to refresh UI with synced data
                          ref.invalidate(noteProvider);
                          ref.invalidate(foldersProvider);

                          ref.read(syncStatusProvider.notifier).state =
                              'In Sync';
                          if (ref.context.mounted) {
                            ScaffoldMessenger.of(ref.context).showSnackBar(
                              const SnackBar(
                                content: Text('Sync completed successfully'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          ref.read(syncStatusProvider.notifier).state = 'Error';
                          debugPrint('Sync error: $e');
                          if (ref.context.mounted) {
                            ScaffoldMessenger.of(ref.context).showSnackBar(
                              SnackBar(
                                content: const Text('Sync failed'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
              ),
              SwitchListTile(
                title: Text(
                  'Auto-Sync',
                  style: TextStyle(color: isCloudEnabled ? null : Colors.grey),
                ),
                value:
                    isCloudEnabled &&
                    authStatus == AuthStatus.loggedIn &&
                    autoSync,
                onChanged:
                    !(isCloudEnabled && authStatus == AuthStatus.loggedIn)
                    ? null
                    : (bool value) async {
                        ref.read(autoSyncProvider.notifier).state = value;
                        final appwriteService = ref.read(
                          appwriteServiceProvider,
                        );
                        if (value) {
                          appwriteService.startAutoSync(
                            ref.read(noteRepositoryProvider),
                            await ref.read(folderRepositoryProvider.future),
                            ref.read(attachmentRepositoryProvider),
                          );
                        } else {
                          appwriteService.stopAutoSync();
                        }
                      },
                secondary: const Icon(Icons.sync_disabled_rounded),
              ),
            ],
          ),
          const Divider(), // Added separator
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Trash Bin'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashBinPage()),
              );
            },
          ),
          const Divider(), // Added separator
          const Spacer(), // Pushes the following ListTile to the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final resetService = ref.read(resetServiceProvider);
                  Navigator.pop(context);
                  Future.microtask(() {
                    if (rootContext.mounted) {
                      _showResetConfirmationDialog(rootContext, resetService);
                    }
                  });
                },
                icon: const Icon(Icons.warning_rounded, size: 20),
                label: const Text('Reset App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getApiKeyIconColor(ApiKeyStatus status) {
    return switch (status) {
      ApiKeyStatus.valid => Colors.green,
      ApiKeyStatus.invalid => Colors.red,
      ApiKeyStatus.notSet => Colors.grey,
      ApiKeyStatus.unknown => Colors.grey,
    };
  }

  Color? _getCloudIconColor(bool isCloudEnabled, AuthStatus authStatus) {
    if (!isCloudEnabled) {
      return Colors.grey;
    }
    return switch (authStatus) {
      AuthStatus.loggedIn => Colors.green,
      AuthStatus.error => Colors.red,
      AuthStatus.loggedOut || AuthStatus.loading => null,
    };
  }

  Future<void> _showResetConfirmationDialog(
    BuildContext context,
    ResetService resetService,
  ) async {
    debugPrint('Showing first reset confirmation dialog');
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Application?'),
          content: const Text(
            'Are you sure you want to reset everything? This action cannot be undone and will delete all your ideas, vaults, and password.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                debugPrint('User cancelled reset in first dialog');
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Reset',
                style: TextStyle(color: AppColors.error),
              ),
              onPressed: () {
                debugPrint('User confirmed reset in first dialog');
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    debugPrint('First dialog result: $result');
    if (result == true) {
      debugPrint('Proceeding to second confirmation dialog');
      if (!context.mounted) {
        debugPrint('Context not mounted, returning');
        return;
      }
      try {
        debugPrint('Calling _showFinalResetConfirmationDialog');
        if (context.mounted) {
          _showFinalResetConfirmationDialog(context, resetService);
        }
        debugPrint('Finished calling _showFinalResetConfirmationDialog');
      } catch (e, stacktrace) {
        debugPrint('Error calling _showFinalResetConfirmationDialog: $e');
        debugPrint('Stack trace: $stacktrace');
      }
    } else {
      debugPrint('Reset cancelled or dialog dismissed');
    }
  }

  Future<void> _showFinalResetConfirmationDialog(
    BuildContext context,
    ResetService resetService,
  ) async {
    debugPrint('Showing second reset confirmation dialog');
    debugPrint('Context mounted: ${context.mounted}');
    final TextEditingController resetTextController = TextEditingController();
    debugPrint('Text controller created');
    try {
      debugPrint('About to show dialog');
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          debugPrint('Building second dialog');
          return AlertDialog(
            title: const Text('Confirm Reset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'To confirm, please type "RESET" in the field below:',
                ),
                TextField(
                  controller: resetTextController,
                  decoration: const InputDecoration(hintText: 'RESET'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  debugPrint('User cancelled reset in second dialog');
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: AppColors.error),
                ),
                onPressed: () {
                  debugPrint(
                    'User attempted to confirm reset in second dialog',
                  );
                  debugPrint('Text entered: "${resetTextController.text}"');
                  if (resetTextController.text == 'RESET') {
                    debugPrint('Correct text entered, proceeding with reset');
                    Navigator.of(context).pop(true);
                  } else {
                    debugPrint('Incorrect text entered');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect input. Please type "RESET".'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
      debugPrint('Dialog closed with result: $result');

      debugPrint('Second dialog result: $result');
      if (result == true) {
        debugPrint('Performing reset');
        if (!context.mounted) return;
        await _performReset(context, resetService);
      } else {
        debugPrint('Reset cancelled or dialog dismissed in second dialog');
      }
    } catch (e, stacktrace) {
      debugPrint('Error in second dialog: $e');
      debugPrint('Stack trace: $stacktrace');
    } finally {
      debugPrint('Disposing text controller');
      resetTextController.dispose();
    }
  }

  Future<void> _performReset(
    BuildContext context,
    ResetService resetService,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSizes.space_16),
              Text('Resetting application...'),
            ],
          ),
        );
      },
    );

    try {
      await resetService.resetAppData();

      if (!context.mounted) return;
      // Close loading indicator
      Navigator.of(context).pop();

      // Navigate to PassphraseSetupPage and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const passphrase_setup.PassphraseSetupPage(),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e, stacktrace) {
      // Catch error and stacktrace
      debugPrint('Error resetting application: $e');
      debugPrint('Stacktrace: $stacktrace');
      if (!context.mounted) return;
      // Close loading indicator
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting application: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}
