import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorServiceProvider = Provider<ErrorService>((ref) {
  return ErrorService();
});

class ErrorService {
  void handleException(
    BuildContext context,
    dynamic error,
    StackTrace stackTrace, {
    String? message,
  }) {
    debugPrint('Error: $error\nStackTrace: $stackTrace');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'An unexpected error occurred.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
