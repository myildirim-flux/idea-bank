import 'package:flutter_riverpod/legacy.dart';

enum AuthStatus { loggedIn, loggedOut, loading, error }

final authStatusProvider = StateProvider<AuthStatus>((ref) {
  return AuthStatus.loggedOut;
});
