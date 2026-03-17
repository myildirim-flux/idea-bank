import 'package:flutter/foundation.dart';

@immutable
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final String? noteId;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.noteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'noteId': noteId,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      noteId: json['noteId'] as String?,
    );
  }
}