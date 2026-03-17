import 'package:flutter/material.dart';

class ApiKeyInfoDialog extends StatelessWidget {
  const ApiKeyInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to Get a Gemini API Key'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. Go to aistudio.google.com'),
          SizedBox(height: 8),
          Text('2. Login with your Google account'),
          SizedBox(height: 8),
          Text('3. Click "Get API key"'),
          SizedBox(height: 8),
          Text('4. Click "Create API key"'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}