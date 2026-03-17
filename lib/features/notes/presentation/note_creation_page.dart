import 'dart:convert'; // For base64Encode

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idea_bank/core/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:idea_bank/core/models.dart';
import 'package:idea_bank/features/ai/presentation/ai_chat_page.dart'; // Import the AI chat page
import 'package:idea_bank/features/folders/presentation/folder_providers.dart';
import 'package:idea_bank/features/notes/models/attachment_model.dart'; // Import attachment model
import 'package:idea_bank/features/notes/presentation/drawing_page.dart';
import 'package:idea_bank/features/notes/presentation/note_providers.dart';
import 'package:idea_bank/features/notes/presentation/widgets/attachment_tile.dart'; // Import attachment tile
import 'package:idea_bank/features/notes/services/attachment_service.dart'; // Import attachment service

class NoteCreationPage extends ConsumerStatefulWidget {
  final Note? note;
  final String? initialFolderId;

  const NoteCreationPage({super.key, this.note, this.initialFolderId});

  @override
  ConsumerState<NoteCreationPage> createState() => _NoteCreationPageState();
}

class _NoteCreationPageState extends ConsumerState<NoteCreationPage> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late String _selectedFolderId;
  String? _drawingPreview; // To store base64 encoded drawing preview
  String? _strokesData; // To store raw stroke data
  List<Attachment> _attachments = []; // To store attachments for the note
  final ValueNotifier<bool> _isAttaching = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title);
    _bodyController = TextEditingController(text: widget.note?.body);
    _selectedFolderId =
        widget.note?.folderId ?? widget.initialFolderId ?? 'all_notes';
    _drawingPreview = widget.note?.drawingPreview;
    _strokesData = widget.note?.strokes;
    _loadAttachments();
  }

  void _loadAttachments() async {
    if (widget.note != null) {
      final attachmentService = ref.read(attachmentServiceProvider);
      final loadedAttachments = await attachmentService.getAttachmentsForNote(
        widget.note!.id,
      );
      if (!mounted) return;
      setState(() {
        _attachments = loadedAttachments;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showSpeechToTextDialog() async {
    final permStatus = await Permission.microphone.request();
    if (permStatus.isGranted) {
      if (!mounted) return;

      // Fresh instance per invocation avoids stale-listener issues.
      final stt = SpeechToText();

      // Pre-initialize BEFORE the dialog so we know immediately if the
      // speech engine is available.
      bool engineReady = false;
      try {
        engineReady = await stt.initialize();
      } catch (e) {
        debugPrint('SpeechToText.initialize() threw: $e');
      }

      if (!mounted) return;

      if (!engineReady) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Speech Recognition Unavailable'),
            content: const Text(
              'Speech recognition is not available on this device. '
              'Please check that Google Speech Services is installed and enabled.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Local state scoped to this dialog invocation.
      bool isListening = false;
      String lastWords = '';

      final transcribedText = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogCtx) {
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return AlertDialog(
                title: const Text('Speech to Text'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lastWords),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (!isListening) {
                          try {
                            setDialogState(() {
                              isListening = true;
                              lastWords = 'Listening...';
                            });
                            stt.listen(
                              onResult: (result) {
                                setDialogState(() {
                                  lastWords = result.recognizedWords;
                                });
                              },
                            );
                          } catch (e) {
                            setDialogState(() {
                              isListening = false;
                              lastWords = 'Error: $e';
                            });
                          }
                        } else {
                          await stt.stop();
                          setDialogState(() {
                            isListening = false;
                          });
                        }
                      },
                      child: Text(
                        isListening ? 'Stop Recording' : 'Start Recording',
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      stt.stop();
                      Navigator.of(dialogCtx).pop(lastWords);
                    },
                    child: const Text('Add to Idea'),
                  ),
                  TextButton(
                    onPressed: () {
                      stt.cancel();
                      Navigator.of(dialogCtx).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _bodyController.text +=
              (transcribedText.isNotEmpty ? '\n\n' : '') + transcribedText;
        });
      }
    } else {
      // Handle permission denied case
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
              'Microphone permission is required for speech-to-text functionality. Please enable it in app settings.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final noteNotifier = ref.read(noteProvider.notifier);
    final attachmentService = ref.read(
      attachmentServiceProvider,
    ); // Access the attachment service

    // Helper to reload attachments
    void loadAttachments() async {
      if (widget.note != null) {
        final loadedAttachments = await attachmentService.getAttachmentsForNote(
          widget.note!.id,
        );
        if (!mounted) return;
        setState(() {
          _attachments = loadedAttachments;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Idea' : 'Edit Idea'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          SizedBox(
            width: 120, // Adjust width as needed
            height: 48, // Adjust height as needed
            child: TextButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
              onPressed: () async {
                if (_titleController.text.trim().isEmpty ||
                    _bodyController.text.trim().isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Cannot Save Empty Idea'),
                        content: const Text(
                          'Title and description cannot be empty.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  foldersAsync.whenData((folders) async {
                    _isAttaching.value = true; // Start loading
                    try {
                      final selectedFolder = folders.firstWhere(
                        (folder) => folder.id == _selectedFolderId,
                      );
                      if (widget.note == null) {
                        final newNote = Note(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          folderId: _selectedFolderId,
                          title: _titleController.text,
                          body: _bodyController.text,
                          createdAt: DateTime.now(),
                          lastModified: DateTime.now(),
                          isDeleted: false,
                          color: selectedFolder.color,
                          drawingPreview: _drawingPreview,
                          strokes: _strokesData,
                        );
                        await noteNotifier.addNote(newNote);
                      } else {
                        final updatedNote = widget.note!.copyWith(
                          title: _titleController.text,
                          body: _bodyController.text,
                          folderId: _selectedFolderId,
                          color: selectedFolder
                              .color, // Add this line to update the color
                          drawingPreview: _drawingPreview,
                          strokes: _strokesData,
                          lastModified: DateTime.now(),
                        );
                        await noteNotifier.updateNote(updatedNote);
                      }
                      if (ref.context.mounted) {
                        Navigator.pop(ref.context);
                      }
                    } finally {
                      _isAttaching.value = false; // Stop loading
                    }
                  });
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isAttaching,
            builder: (context, isAttaching, child) {
              if (isAttaching) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () async {
                  if (widget.note?.id == null) {
                    // Show a dialog that note must be saved first
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Save Idea First'),
                          content: const Text(
                            'Please save the idea before adding attachments.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    _isAttaching.value = true; // Start loading
                    try {
                      final newAttachment = await attachmentService
                          .addAttachment(widget.note!.id);
                      if (newAttachment != null) {
                        loadAttachments(); // Reload attachments after adding
                        if (!ref.context.mounted) return;
                        ScaffoldMessenger.of(ref.context).showSnackBar(
                          const SnackBar(content: Text('Attachment added!')),
                        );
                      } else {
                        if (!ref.context.mounted) return;
                        ScaffoldMessenger.of(ref.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No file selected or attachment failed.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!ref.context.mounted) return;
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add attachment: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      _isAttaching.value = false; // Stop loading
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            foldersAsync.when(
              data: (folders) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedFolderId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFolderId = newValue!;
                    });
                  },
                  items: folders.map<DropdownMenuItem<String>>((Folder folder) {
                    return DropdownMenuItem<String>(
                      value: folder.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: folder.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(folder.name),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Vault',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading folders: $error'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            if (_drawingPreview != null)
              Expanded(
                child: Builder(
                  builder: (context) {
                    try {
                      debugPrint(
                        'Drawing preview length: ${_drawingPreview?.length}',
                      );
                      if (_drawingPreview != null &&
                          _drawingPreview!.length > 50) {
                        debugPrint(
                          'Drawing preview start: ${_drawingPreview!.substring(0, 50)}',
                        );
                      }

                      final bytes = base64Decode(_drawingPreview!);
                      return Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error rendering drawing preview: $error');
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                ),
                                Text('Error loading image: $error'),
                              ],
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      debugPrint('Error decoding drawing preview base64: $e');
                      return const Center(
                        child: Text('Error decoding image data'),
                      );
                    }
                  },
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null, // Allows multiple lines
                    expands: true, // Takes up remaining vertical space
                    textAlignVertical: TextAlignVertical.top,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag:
                              'ai_chat_button', // Unique tag for this button
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Start AI Chat?'),
                                  content: const Text(
                                    'Do you want to start a chat with the AI based on your idea description?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AiChatPage(
                                              noteId: widget.note?.id,
                                              noteTitle: _titleController.text,
                                              noteDescription:
                                                  _bodyController.text,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Start Chat'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Icon(Icons.psychology_alt),
                        ),
                        const SizedBox(width: 8), // Space between buttons
                        FloatingActionButton(
                          mini: true,
                          heroTag:
                              'speech_to_text_button', // Unique tag for this button
                          onPressed: _showSpeechToTextDialog,
                          child: const Icon(Icons.mic),
                        ),
                        const SizedBox(width: 8), // Space between buttons
                        FloatingActionButton(
                          mini: true,
                          heroTag:
                              'drawing_button', // Unique tag for this button
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DrawingPage(strokes: _strokesData),
                              ),
                            );

                            if (result != null && result is Map) {
                              setState(() {
                                _drawingPreview = result['preview'];
                                _strokesData = result['strokes'];
                              });
                              if (!ref.context.mounted) return;
                              ScaffoldMessenger.of(ref.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Drawing saved successfully!'),
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Display Attachments
            if (_attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Attachments:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true, // Important for nested ListViews
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = _attachments[index];
                      return AttachmentTile(
                        attachment: attachment,
                        onAttachmentDeleted:
                            loadAttachments, // Pass the reload callback
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
