import 'package:flutter/foundation.dart';
import 'package:idea_bank/features/ai/data/chat_repository.dart';
import 'package:idea_bank/features/ai/models/chat_message.dart';
import 'package:idea_bank/features/ai/models/chat_session.dart';
import 'package:idea_bank/features/ai/services/ai_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_providers.g.dart';

@immutable
class ChatState {
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final List<ChatMessage> currentMessages;
  final bool isLoading;

  const ChatState({
    this.sessions = const [],
    this.activeSessionId,
    this.currentMessages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    List<ChatMessage>? currentMessages,
    bool? isLoading,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  final Uuid _uuid = const Uuid();

  @override
  Future<ChatState> build(String? noteId) async {
    final sessions = await ref
        .watch(chatRepositoryProvider(noteId: noteId))
        .getSessions();
    if (sessions.isNotEmpty) {
      final activeSessionId = sessions.first.id;
      final messages = await ref
          .watch(chatRepositoryProvider(noteId: noteId))
          .getMessages(activeSessionId);
      return ChatState(
        sessions: sessions,
        activeSessionId: activeSessionId,
        currentMessages: messages,
      );
    } else {
      return const ChatState();
    }
  }

  Future<void> loadSessions() async {
    if (!state.hasValue) return; // Guard against null state
    state = AsyncData(state.value!.copyWith(isLoading: true));
    final sessions = await ref
        .read(chatRepositoryProvider(noteId: noteId))
        .getSessions();
    if (sessions.isNotEmpty) {
      await loadMessages(sessions.first.id);
    } else {
      state = const AsyncData(ChatState(sessions: []));
    }
  }

  Future<void> loadMessages(String sessionId) async {
    if (!state.hasValue) return; // Guard against null state
    state = AsyncData(state.value!.copyWith(isLoading: true));
    final messages = await ref
        .read(chatRepositoryProvider(noteId: noteId))
        .getMessages(sessionId);
    final sessions = await ref
        .read(chatRepositoryProvider(noteId: noteId))
        .getSessions();
    state = AsyncData(
      state.value!.copyWith(
        sessions: sessions,
        activeSessionId: sessionId,
        currentMessages: messages,
        isLoading: false,
      ),
    );
  }

  Future<void> sendMessage(String text, {String? initialContext}) async {
    if (!state.hasValue) return; // Guard against null state
    var activeSessionId = state.value!.activeSessionId;
    if (activeSessionId == null) {
      await startNewChat(
        title: text.substring(0, text.length > 50 ? 50 : text.length),
      );
      activeSessionId = state.value!.activeSessionId;
    }

    state = AsyncData(state.value!.copyWith(isLoading: true));

    final fullMessage = initialContext != null
        ? '$initialContext\n\n$text'
        : text;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sessionId: activeSessionId!,
      content: text, // Store the original user message
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );

    await ref
        .read(chatRepositoryProvider(noteId: noteId))
        .addMessage(userMessage);

    // Optimistically update the UI
    final updatedMessages = [...state.value!.currentMessages, userMessage];
    state = AsyncData(state.value!.copyWith(currentMessages: updatedMessages));

    try {
      final aiService = ref.read(aiServiceProvider);
      if (aiService.isInitialized) {
        final response = await aiService.getCompletion(fullMessage);
        final modelMessage = ChatMessage(
          id: _uuid.v4(),
          sessionId: activeSessionId,
          content: response,
          type: ChatMessageType.model,
          timestamp: DateTime.now(),
        );
        await ref
            .read(chatRepositoryProvider(noteId: noteId))
            .addMessage(modelMessage);
        await loadMessages(activeSessionId); // Refresh messages
      } else {
        throw Exception('AI service not initialized. Please check API key.');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      if (state is! AsyncError) {
        state = AsyncData(state.value!.copyWith(isLoading: false));
      }
    }
  }

  Future<void> startNewChat({String? title}) async {
    if (!state.hasValue) {
      state = const AsyncData(ChatState(isLoading: true));
    } else {
      state = AsyncData(state.value!.copyWith(isLoading: true));
    }
    final newSession = await ref
        .read(chatRepositoryProvider(noteId: noteId))
        .createSession(title: title);
    final sessions = [newSession, ...state.value?.sessions ?? <ChatSession>[]];
    state = AsyncData(
      state.value!.copyWith(
        sessions: sessions,
        activeSessionId: newSession.id,
        currentMessages: [],
        isLoading: false,
      ),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    if (!state.hasValue) return; // Guard against null state
    final chatRepository = ref.read(chatRepositoryProvider(noteId: noteId));
    await chatRepository.deleteSession(sessionId);
    final sessions = state.value!.sessions
        .where((s) => s.id != sessionId)
        .toList();
    if (state.value!.activeSessionId == sessionId) {
      if (sessions.isNotEmpty) {
        await loadMessages(sessions.first.id);
      } else {
        state = const AsyncData(ChatState(sessions: []));
      }
    } else {
      state = AsyncData(state.value!.copyWith(sessions: sessions));
    }
  }
}
