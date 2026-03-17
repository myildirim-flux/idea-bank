import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:idea_bank/core/services/encryption_service.dart'; // Import EncryptionService

import 'package:idea_bank/features/notes/presentation/note_creation_page.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/home/presentation/widgets/_app_bar.dart'
    as custom_app_bar;
import 'package:idea_bank/features/home/presentation/widgets/_folders_section.dart';
import 'package:idea_bank/features/home/presentation/widgets/_search_results_view.dart';
import 'package:idea_bank/features/home/presentation/widgets/_home_drawer.dart';
import 'package:idea_bank/features/home/presentation/widgets/_notes_section.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _searchController;
  bool _hasPassphrase = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _checkPassphraseStatus();
  }

  Future<void> _checkPassphraseStatus() async {
    final encryptionService = ref.read(encryptionServiceProvider);
    final hasKey = await encryptionService.readKey() != null;
    setState(() {
      _hasPassphrase = hasKey;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = ref.watch(showSearchResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            custom_app_bar.AppBar(searchController: _searchController),
            if (showSearchResults)
              const SearchResultsView()
            else
              SliverPadding(
                padding: AppSizes.pagePadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const FoldersSection(),
                    const SizedBox(height: AppSizes.space_24),
                    const NotesSection(),
                  ]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.large(
          onPressed: () {
            final selectedFolderId = ref.read(selectedFolderIdProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    NoteCreationPage(initialFolderId: selectedFolderId),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add_rounded, size: AppSizes.icon_32),
        ),
      ),
      endDrawer: HomeDrawer(
        hasPassphrase: _hasPassphrase,
        rootContext: context,
      ),
    );
  }
}
