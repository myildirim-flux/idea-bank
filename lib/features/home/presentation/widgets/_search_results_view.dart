import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/core/utils.dart' as utils;
import 'package:idea_bank/features/notes/presentation/note_creation_page.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';

class SearchResultsView extends ConsumerWidget {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredNotesAsync = ref.watch(
      allNotesProvider,
    ); // Use allNotesProvider for search results

    return filteredNotesAsync.when(
      data: (filteredNotesData) {
        return SliverPadding(
          padding: AppSizes.searchResultsPadding, // Adjust padding as needed
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (filteredNotesData.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.space_20),
                  child: Text(
                    'No ideas found for this search.',
                    style: TextStyle(
                      fontSize: AppSizes.font_16,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
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
                  itemCount: filteredNotesData.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotesData[index];
                    return _NoteCard(
                      note: note,
                      formatDateTime: utils.formatDateTime,
                    );
                  },
                ),
            ]),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) =>
          SliverFillRemaining(child: Center(child: Text('Error: $error'))),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, required this.formatDateTime});

  final Note note;
  final String Function(DateTime) formatDateTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDecryptionError = ref.watch(decryptionErrorProvider);

    return GestureDetector(
      onTap: () {
        if (note.isEncrypted && hasDecryptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot open encrypted idea due to decryption error.',
              ),
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
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.red),
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
        margin: const EdgeInsets.only(bottom: AppSizes.space_12),
        padding: AppSizes.noteCardPadding,
        decoration: BoxDecoration(
          color: note.color.withAlpha((255 * 0.15).round()),
          borderRadius: AppSizes.radius_16,
          border: Border.all(
            color: note.color.withAlpha((255 * 0.4).round()),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSizes.space_4,
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
                      fontSize: AppSizes.font_18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                    maxLines: 2, // Allow title to wrap
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // All notes are encrypted now
                const Icon(
                  Icons.lock,
                  size: AppSizes.icon_20,
                  color: AppColors.white,
                ),
                if (note.hasAttachments) // Display attachment icon
                  const Padding(
                    padding: EdgeInsets.only(left: AppSizes.space_8),
                    child: Icon(
                      Icons.attachment,
                      size: AppSizes.icon_20,
                      color: AppColors.white,
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
