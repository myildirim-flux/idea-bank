import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:intl/intl.dart';

class TrashBinPage extends ConsumerWidget {
  const TrashBinPage({super.key});

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day of the week
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedNotesAsync = ref.watch(trashedNotesProvider);
    final noteNotifier = ref.read(noteProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Trash?'),
                  content: const Text(
                    'Are you sure you want to permanently delete all ideas in the trash? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        noteNotifier.clearTrash();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: trashedNotesAsync.when(
        data: (trashedNotes) {
          return trashedNotes.isEmpty
              ? const Center(child: Text('Trash bin is empty.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (MediaQuery.of(context).size.width / 160)
                        .floor()
                        .clamp(2, 4),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: trashedNotes.length,
                  itemBuilder: (context, index) {
                    final note = trashedNotes[index];
                    return _TrashedNoteCard(
                      note: note,
                      formatDateTime: _formatDateTime,
                      onRestore: () async {
                        noteNotifier.restoreNote(note.id);
                      },
                      onDeletePermanently: () async {
                        noteNotifier.deleteNotePermanently(note.id);
                      },
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _TrashedNoteCard extends StatelessWidget {
  const _TrashedNoteCard({
    required this.note,
    required this.formatDateTime,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final Note note;
  final Function(DateTime) formatDateTime;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.noteCardPadding,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.lock,
                size: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deleted: ${formatDateTime(note.deletedAt!)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(
                  Icons.restore_from_trash,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: onRestore,
              ),
              const SizedBox(width: 8),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(
                  Icons.delete_forever,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: onDeletePermanently,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
