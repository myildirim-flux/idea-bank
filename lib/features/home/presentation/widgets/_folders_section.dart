import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/features/folders/data/folder_repository.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/folders/presentation/widgets/folder_creation_dialog.dart';

class FoldersSection extends ConsumerWidget {
  const FoldersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      data: (folders) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_special_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Vaults',
                  style: TextStyle(
                    fontSize: AppSizes.font_18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space_14),
            SizedBox(
              height: AppSizes.folderListHeight + 8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: folders.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSizes.space_12),
                itemBuilder: (context, index) {
                  if (index == folders.length) {
                    // "Add Folder" button
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const FolderCreationDialog(),
                        );
                      },
                      child: Container(
                        width: AppSizes.folderCardWidth,
                        padding: AppSizes.folderCardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: AppSizes.radius_16,
                          border: Border.all(
                            color: AppColors.blueGrey700.withValues(alpha: 0.4),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.space_8),
                            Text(
                              'New Vault',
                              style: TextStyle(
                                fontSize: AppSizes.font_14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final folder = folders[index];
                  final isSelected =
                      ref.watch(selectedFolderIdProvider) == folder.id;

                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(selectedFolderIdProvider.notifier)
                          .setSelectedFolder(folder.id);
                    },
                    onLongPress: () {
                      if (folder.id == 'all_notes') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Cannot delete "All Ideas" vault.',
                            ),
                            backgroundColor: AppColors.surfaceLight,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return FutureBuilder<FolderRepository>(
                            future: ref.read(folderRepositoryProvider.future),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              final folderRepository = snapshot.data!;
                              return FutureBuilder<bool>(
                                future: folderRepository.hasNotesInFolder(
                                  folder.id,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final hasNotes = snapshot.data ?? false;
                                  return AlertDialog(
                                    title: Text('Delete "${folder.name}"?'),
                                    content: hasNotes
                                        ? const Text(
                                            'This vault contains ideas. Deleting it will also delete all ideas within it.',
                                          )
                                        : const Text(
                                            'Are you sure you want to delete this vault?',
                                          ),
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
                                          style: TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(foldersProvider.notifier)
                                              .deleteFolder(folder.id);
                                          if (!context.mounted) return;
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: AppSizes.folderCardWidth,
                      padding: AppSizes.folderCardPadding,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  folder.color.withValues(alpha: 0.25),
                                  folder.color.withValues(alpha: 0.12),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : AppColors.surfaceDark,
                        borderRadius: AppSizes.radius_16,
                        border: Border.all(
                          color: isSelected
                              ? folder.color.withValues(alpha: 0.6)
                              : AppColors.blueGrey700.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: folder.color.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: folder.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 20,
                              color: folder.color,
                            ),
                          ),
                          Text(
                            folder.name,
                            style: const TextStyle(
                              fontSize: AppSizes.font_16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${folder.noteCount} ideas',
                                style: TextStyle(
                                  fontSize: AppSizes.font_12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
