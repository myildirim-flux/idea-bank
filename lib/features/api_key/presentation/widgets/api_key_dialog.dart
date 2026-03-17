import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/api_key/presentation/api_key_providers.dart';
import 'package:idea_bank/features/api_key/presentation/widgets/api_key_info_dialog.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Enter Gemini API Key'),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ApiKeyInfoDialog(),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
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
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final apiKey = _apiKeyController.text;

            if (apiKey.isEmpty) {
              debugPrint('ApiKeyDialog: API key is empty, not proceeding.');
              setState(() {
                _errorMessage = 'API Key cannot be empty.';
              });
              return;
            }

            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });

            final notifier = ref.read(apiKeyStatusProvider.notifier);
            final isValid = await notifier.checkAndSaveApiKey(apiKey);
            debugPrint('ApiKeyDialog: checkAndSaveApiKey returned: $isValid');

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              if (isValid) {
                debugPrint('ApiKeyDialog: Key is valid, closing dialog.');
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                debugPrint(
                  'ApiKeyDialog: Key is invalid, showing error in dialog.',
                );
                setState(() {
                  _errorMessage = 'Invalid API Key.';
                });
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
