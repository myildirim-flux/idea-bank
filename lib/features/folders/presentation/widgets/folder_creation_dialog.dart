import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';

class FolderCreationDialog extends ConsumerStatefulWidget {
  const FolderCreationDialog({super.key});

  @override
  ConsumerState<FolderCreationDialog> createState() =>
      _FolderCreationDialogState();
}

class _FolderCreationDialogState extends ConsumerState<FolderCreationDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue; // Default color

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.yellow,
    Colors.red,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    if (_nameController.text.isNotEmpty) {
      final newFolder = Folder(
        id: const Uuid().v4(),
        name: _nameController.text,
        color: _selectedColor,
        lastModified: DateTime.now(),
      );
      await ref.read(foldersProvider.notifier).addFolder(newFolder);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Vault'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Vault Name'),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('Select Color:'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _availableColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createFolder, child: const Text('Create')),
      ],
    );
  }
}
