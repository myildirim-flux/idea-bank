import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/features/notes/models/attachment_model.dart';
import 'package:idea_bank/features/notes/services/attachment_service.dart';

class AttachmentTile extends ConsumerWidget {
  final Attachment attachment;
  final VoidCallback onAttachmentDeleted;

  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.onAttachmentDeleted,
  });

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) {
      return Icons.insert_drive_file;
    }
    if (fileType.startsWith('image/')) {
      return Icons.image;
    } else if (fileType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (fileType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (fileType.startsWith('video/')) {
      return Icons.video_file;
    } else if (fileType == 'application/msword' ||
        fileType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return Icons.description; // Word document
    } else if (fileType == 'application/vnd.ms-excel' ||
        fileType == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return Icons.table_chart; // Excel document
    } else if (fileType == 'application/vnd.ms-powerpoint' ||
        fileType == 'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
      return Icons.slideshow; // PowerPoint document
    } else if (fileType == 'text/plain') {
      return Icons.text_snippet; // Text file
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentService = ref.read(attachmentServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(_getFileIcon(attachment.fileType)),
        title: Text(attachment.originalFilename),
        subtitle: Text('${(attachment.fileSize! / 1024).toStringAsFixed(2)} KB'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            // Show confirmation dialog
            final bool? confirmDelete = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Delete Attachment'),
                  content: Text('Are you sure you want to delete "${attachment.originalFilename}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );

            if (confirmDelete == true) {
              try {
                await attachmentService.deleteAttachment(attachment.id);
                onAttachmentDeleted(); // Callback to refresh the parent UI
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attachment deleted.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete attachment: $e')),
                );
              }
            }
          },
        ),
        onTap: () async {
          try {
            await attachmentService.openAttachment(attachment);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open attachment: $e')),
            );
          }
        },
      ),
    );
  }
}