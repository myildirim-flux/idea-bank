import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/ai/models/chat_message.dart';
import 'package:idea_bank/features/ai/presentation/chat_providers.dart';
import 'package:idea_bank/features/api_key/presentation/api_key_providers.dart';
import 'package:idea_bank/features/api_key/presentation/widgets/api_key_dialog.dart';

class AiChatPage extends ConsumerStatefulWidget {
  final String? noteId;
  final String? noteTitle;
  final String? noteDescription;

  const AiChatPage({
    super.key,
    this.noteId,
    this.noteTitle,
    this.noteDescription,
  });

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String? _initialContext;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.noteTitle != null && widget.noteDescription != null) {
      _initialContext =
          'Note Title: ${widget.noteTitle}\n\nNote Description: ${widget.noteDescription}';
    }
    // We no longer send the message automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider(widget.noteId).notifier).loadSessions();
      _checkApiKey();
    });
  }

  void _checkApiKey() {
    final apiKeyStatus = ref.read(apiKeyStatusProvider);
    if (apiKeyStatus != ApiKeyStatus.valid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => const ApiKeyDialog(),
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(chatProvider(widget.noteId).notifier);
    if (_initialContext != null) {
      notifier.sendMessage(text, initialContext: _initialContext);
      _initialContext = null; // Clear after sending
    } else {
      notifier.sendMessage(text);
    }
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.noteId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.noteTitle != null
              ? 'AI Chat (${widget.noteTitle})'
              : 'AI Chat',
        ),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                ref.read(chatProvider(widget.noteId).notifier).startNewChat(),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: chatState.when(
          data: (data) => ListView.builder(
            itemCount: data.sessions.length,
            itemBuilder: (context, index) {
              final session = data.sessions[index];
              return ListTile(
                title: Text(session.title),
                onTap: () {
                  ref
                      .read(chatProvider(widget.noteId).notifier)
                      .loadMessages(session.id);
                  Navigator.of(context).pop();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(chatProvider(widget.noteId).notifier)
                      .deleteSession(session.id),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              data: (data) {
                final messages = data.currentMessages;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isUser = message.type == ChatMessageType.user;
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(message.content),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: chatState.isLoading ? null : _sendMessage,
                  mini: true,
                  child: chatState.isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
