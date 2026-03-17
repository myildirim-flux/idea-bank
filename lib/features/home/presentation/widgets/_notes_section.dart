import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/notes/presentation/note_creation_page.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';

class NotesSection extends ConsumerWidget {
  const NotesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredNotesAsync = ref.watch(notesProvider);
    final selectedFolder = ref.watch(selectedFolderIdProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return filteredNotesAsync.when(
      data: (filteredNotes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                foldersAsync.when(
                  data: (folders) {
                    return Text(
                      selectedFolder == 'all_notes'
                          ? 'All Ideas'
                          : folders
                                .firstWhere((f) => f.id == selectedFolder)
                                .name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.font_18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) =>
                      Text('Error', style: TextStyle(color: AppColors.error)),
                ),
                const Spacer(),
                if (filteredNotes.isNotEmpty)
                  Text(
                    '${filteredNotes.length} ideas',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space_14),
            if (filteredNotes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ideas yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first idea',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (MediaQuery.of(context).size.width / 160)
                      .floor()
                      .clamp(2, 4),
                  crossAxisSpacing: AppSizes.space_12,
                  mainAxisSpacing: AppSizes.space_12,
                  childAspectRatio: AppSizes.noteCardAspectRatio,
                ),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return _NoteCard(note: note);
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Failed to load notes: $error')),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDecryptionError = ref.watch(decryptionErrorProvider);

    return GestureDetector(
      onTap: () {
        if (note.isEncrypted && hasDecryptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Cannot open encrypted idea due to decryption error.',
              ),
              backgroundColor: AppColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteCreationPage(note: note),
            ),
          );
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final noteNotifier = ref.read(noteProvider.notifier);
            return AlertDialog(
              title: const Text('Delete Idea?'),
              content: const Text('This idea will be moved to trash.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onPressed: () async {
                    noteNotifier.softDeleteNote(note.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: AppSizes.noteCardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: AppSizes.radius_16,
          border: Border.all(
            color: note.color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: note.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title ?? '',
                    style: const TextStyle(
                      fontSize: AppSizes.font_16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Lock icon with badge style
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                if (note.hasAttachments)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
