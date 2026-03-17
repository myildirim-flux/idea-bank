import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:idea_bank/core/env.dart';
import 'package:idea_bank/features/auth/services/auth_service.dart';
import 'package:idea_bank/features/cloud/services/appwrite_service.dart';
import 'package:idea_bank/features/notes/data/attachment_repository.dart';
import 'package:idea_bank/core/services/database_service.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return AttachmentRepository(databaseService);
});

final appwriteClientProvider = Provider<Client?>((ref) {
  if (Env.appwriteEndpoint.isEmpty || Env.appwriteProjectId.isEmpty) {
    return null;
  }
  return Client()
    ..setEndpoint(Env.appwriteEndpoint)
    ..setProject(Env.appwriteProjectId);
});

final appwriteApiClientProvider = Provider<Client?>((ref) {
  if (Env.appwriteEndpoint.isEmpty ||
      Env.appwriteProjectId.isEmpty ||
      Env.appwriteApiKey.isEmpty) {
    return null;
  }
  return Client()
    ..setEndpoint(Env.appwriteEndpoint)
    ..setProject(Env.appwriteProjectId)
    ..setDevKey(Env.appwriteApiKey);
});

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  final sessionClient = ref.watch(appwriteClientProvider);
  final apiClient = ref.watch(appwriteApiClientProvider);
  return AppwriteService(sessionClient, apiClient);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final sessionClient = ref.watch(appwriteClientProvider);
  return AuthService(sessionClient);
});

final autoSyncProvider = StateProvider<bool>((ref) => false);

final syncStatusProvider = StateProvider<String>((ref) => 'In Sync');
