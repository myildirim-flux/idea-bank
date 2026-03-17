import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';

class AppBar extends ConsumerWidget {
  const AppBar({required this.searchController, super.key});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      title: isSearching
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: searchController,
                onChanged: (query) {
                  ref.read(searchQueryProvider.notifier).setQuery(query);
                },
                decoration: InputDecoration(
                  hintText: 'Search your ideas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                autofocus: true,
              ),
            )
          : Row(
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Idea Bank',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          onPressed: () {
            if (isSearching) {
              searchController.clear();
              ref.read(searchQueryProvider.notifier).setQuery('');
            } else {
              ref.read(searchQueryProvider.notifier).setQuery(' ');
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSearching
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: isSearching ? AppColors.error : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.space_8),
      ],
    );
  }
}
