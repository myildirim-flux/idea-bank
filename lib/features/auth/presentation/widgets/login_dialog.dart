import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/auth/presentation/auth_providers.dart';
import 'package:idea_bank/features/cloud/presentation/cloud_providers.dart';
import 'package:appwrite/appwrite.dart' as appwrite;

class LoginDialog extends ConsumerStatefulWidget {
  const LoginDialog({super.key});

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusProvider);
    final authService = ref.read(authServiceProvider);

    return AlertDialog(
      title: const Text('Login to Cloud'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'user@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: authStatus == AuthStatus.loading
              ? null
              : () async {
                  setState(() {
                    _errorMessage = null;
                  });

                  // Otherwise, handle normal login
                  ref.read(authStatusProvider.notifier).state =
                      AuthStatus.loading;
                  try {
                    final user = await authService.login(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                    if (mounted) {
                      if (user != null) {
                        ref.read(authStatusProvider.notifier).state =
                            AuthStatus.loggedIn;
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } else {
                        ref.read(authStatusProvider.notifier).state =
                            AuthStatus.error;
                        setState(() {
                          _errorMessage = 'Login failed. Please try again.';
                        });
                      }
                    }
                  } on appwrite.AppwriteException catch (e) {
                    ref.read(authStatusProvider.notifier).state =
                        AuthStatus.error;
                    setState(() {
                      _errorMessage =
                          e.message ?? 'Login failed with server error.';
                    });
                  } catch (e) {
                    ref.read(authStatusProvider.notifier).state =
                        AuthStatus.error;
                    setState(() {
                      _errorMessage = 'Login failed: ${e.toString()}';
                    });
                  }
                },
          child: authStatus == AuthStatus.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Login'),
        ),
      ],
    );
  }
}
