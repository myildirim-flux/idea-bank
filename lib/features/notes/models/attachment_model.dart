class Attachment {
  final String id;
  final String noteId;
  final String originalFilename;
  final String localPathEncrypted;
  final String iv; // Add IV field
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.noteId,
    required this.originalFilename,
    required this.localPathEncrypted,
    required this.iv, // Add IV to constructor
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'],
      noteId: map['note_id'],
      originalFilename: map['original_filename'],
      localPathEncrypted: map['local_path_encrypted'],
      iv: map['iv'], // Read IV from map
      fileType: map['file_type'],
      fileSize: map['file_size'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'original_filename': originalFilename,
      'local_path_encrypted': localPathEncrypted,
      'iv': iv, // Write IV to map
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Attachment copyWith({
    String? id,
    String? noteId,
    String? originalFilename,
    String? localPathEncrypted,
    String? iv, // Add IV to copyWith
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      originalFilename: originalFilename ?? this.originalFilename,
      localPathEncrypted: localPathEncrypted ?? this.localPathEncrypted,
      iv: iv ?? this.iv, // Add IV to copyWith
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
