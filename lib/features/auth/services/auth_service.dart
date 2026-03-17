import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final appwrite.Client? _sessionClient;
  final FlutterSecureStorage _secureStorage;
  appwrite.Account? _account;

  static const _sessionStorageKey = 'appwrite_session_jwt';

  AuthService(this._sessionClient, [FlutterSecureStorage? secureStorage])
    : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    if (_sessionClient != null) {
      _account = appwrite.Account(_sessionClient);
    }
  }

  /// Attempts to restore a previous session from secure storage.
  /// Called at app startup to avoid creating duplicate sessions.
  Future<models.User?> restoreSession() async {
    if (_account == null) {
      debugPrint('AuthService: Appwrite client not initialized.');
      return null;
    }
    try {
      final storedSession = await _secureStorage.read(key: _sessionStorageKey);
      if (storedSession == null) {
        debugPrint('AuthService: No stored session found.');
        return null;
      }

      // Set the stored session in the Appwrite client
      _account!.client.setSession(storedSession);
      debugPrint('AuthService: Restored session from storage.');

      // Verify the session is still valid by fetching user
      return await _account!.get();
    } on appwrite.AppwriteException catch (e) {
      debugPrint(
        'AuthService: Restored session is invalid - code:${e.code} message:${e.message} response:${e.response}',
      );
      // Session expired or invalid, clear it
      await _secureStorage.delete(key: _sessionStorageKey);
      return null;
    } catch (e) {
      debugPrint('AuthService: Error restoring session - $e');
      return null;
    }
  }

  Future<models.User?> login(String email, String password) async {
    if (_account == null) {
      debugPrint('AuthService: Appwrite client not initialized.');
      return null;
    }
    try {
      // Create a new email/password session
      final session = await _account!.createEmailPasswordSession(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Session created - ${session.$id}');

      // Extract JWT from the session and store it
      // Note: Appwrite SDK handles JWT internally, but we store the session ID as a reference
      await _secureStorage.write(key: _sessionStorageKey, value: session.$id);
      debugPrint('AuthService: Session ID stored in secure storage.');

      // If session creation is successful, get user details
      return await _account!.get();
    } on appwrite.AppwriteException catch (e) {
      if (e.code == 401 && e.type == 'user_session_already_exists') {
        debugPrint(
          'AuthService: Session already exists, clearing and retrying...',
        );
        try {
          // Clear the existing stale session using full logout to ensure storage is also cleared
          await logout();

          debugPrint('AuthService: Retrying login...');
          // Retry login with timeout
          final session = await _account!
              .createEmailPasswordSession(email: email, password: password)
              .timeout(const Duration(seconds: 10));

          debugPrint(
            'AuthService: Session created after retry - ${session.$id}',
          );

          await _secureStorage.write(
            key: _sessionStorageKey,
            value: session.$id,
          );
          return await _account!.get().timeout(const Duration(seconds: 10));
        } catch (retryError) {
          debugPrint('AuthService: Retry failed - $retryError');
          rethrow;
        }
      }

      debugPrint(
        'AuthService: Error logging in - code:${e.code} message:${e.message} response:${e.response}',
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_account == null) return;
    try {
      await _account!.deleteSession(sessionId: 'current');
      debugPrint('AuthService: Logged out successfully.');

      // Clear the stored session from secure storage
      await _secureStorage.delete(key: _sessionStorageKey);
      debugPrint('AuthService: Session cleared from storage.');
    } on appwrite.AppwriteException catch (e) {
      debugPrint(
        'AuthService: Error logging out - code:${e.code} message:${e.message} response:${e.response}',
      );
      // Still clear local storage even if Appwrite call fails
      await _secureStorage.delete(key: _sessionStorageKey);
    }
  }

  Future<bool> isLoggedIn() async {
    if (_account == null) return false;
    try {
      await _account!.get();
      return true;
    } on appwrite.AppwriteException catch (e) {
      debugPrint(
        'AuthService: isLoggedIn check failed - code:${e.code} message:${e.message} response:${e.response}',
      );
      return false;
    }
  }

  Future<models.User?> getUser() async {
    if (_account == null) return null;
    try {
      return await _account!.get();
    } on appwrite.AppwriteException catch (e) {
      debugPrint(
        'AuthService: getUser failed - code:${e.code} message:${e.message} response:${e.response}',
      );
      return null;
    }
  }
}
