import 'package:flutter/foundation.dart';

enum ChatMessageType { user, model }

@immutable
class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final String? encryptedContent;
  final String? salt;
  final String? iv;
  final bool isEncrypted;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.encryptedContent,
    this.salt,
    this.iv,
    this.isEncrypted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'encryptedContent': encryptedContent,
      'salt': salt,
      'iv': iv,
      'isEncrypted': isEncrypted ? 1 : 0,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      content: json['content'] as String,
      type: ChatMessageType.values.byName(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      encryptedContent: json['encryptedContent'] as String?,
      salt: json['salt'] as String?,
      iv: json['iv'] as String?,
      isEncrypted: (json['isEncrypted'] as int? ?? 0) == 1,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    String? encryptedContent,
    String? salt,
    String? iv,
    bool? isEncrypted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      salt: salt ?? this.salt,
      iv: iv ?? this.iv,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
}