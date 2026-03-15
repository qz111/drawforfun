import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../line_art/line_art_engine.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../templates/animal_templates.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isImporting = false;

  List<_CardData> _templateCards = [];
  List<_CardData> _uploadCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // Fetch all three sources in parallel
    final results = await Future.wait<List<_CardData>>([
      Future.wait(
        AnimalTemplates.all.map((template) async {
          final entry = await DrawingRepository.templateEntry(template);
          final hasThumbnail = File(entry.thumbnailPath).existsSync();
          return _CardData(
            entry: entry,
            label: template.name,
            emoji: template.emoji,
            hasThumbnail: hasThumbnail,
          );
        }),
      ),
      DrawingRepository.listRawImportEntries().then((entries) => entries.map((entry) {
        final hasThumbnail = File(entry.thumbnailPath).existsSync();
        return _CardData(
          // _uploadLabel handles both 'upload_YYYYMMDD_...' and 'rawimport_YYYYMMDD_...'
          // because both have the date segment at split('_')[1].
          entry: entry,
          label: _uploadLabel(entry.id),
          emoji: '📷',
          hasThumbnail: hasThumbnail,
        );
      }).toList()),
      DrawingRepository.listUploadEntries().then((entries) => entries.map((entry) {
        final hasThumbnail = File(entry.thumbnailPath).existsSync();
        return _CardData(
          entry: entry,
          label: _uploadLabel(entry.id),
          hasThumbnail: hasThumbnail,
        );
      }).toList()),
    ]);

    if (mounted) {
      setState(() {
        // Built-in templates first, raw imports appended after
        _templateCards = [...results[0], ...results[1]];
        _uploadCards = results[2];
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    // Reload after returning — auto-save may have updated thumbnails
    _loadData();
  }

  Future<void> _startUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final overlayPng =
          await compute(LineArtEngine.convert, result.files.single.bytes!);
      if (overlayPng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not convert image — try a different photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final entry = await DrawingRepository.createUploadEntry(overlayPng);
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
        );
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _startRawImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;

    setState(() => _isImporting = true);
    try {
      await DrawingRepository.createRawImportEntry(result.files.single.bytes!);
      _loadData();
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmDelete(_CardData card) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        entry: card.entry,
        onConfirmed: () {
          setState(() {
            // List.remove uses == which defaults to reference equality for _CardData.
            // This is correct: `card` is the exact same object instance stored in
            // _templateCards / _uploadCards, so reference equality finds it reliably.
            _templateCards.remove(card);
            _uploadCards.remove(card);
          });
        },
      ),
    );
  }

  String _uploadLabel(String id) {
    // id: 'upload_YYYYMMDD_HHmmss' → 'Photo MM/DD'
    try {
      final date = id.split('_')[1]; // YYYYMMDD
      return 'Photo ${date.substring(4, 6)}/${date.substring(6, 8)}';
    } catch (_) {
      return 'Photo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          '🎨 Draw For Fun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Built-in Templates ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🐾 Built-in Templates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                      _isImporting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.deepPurple,
                              tooltip: 'Add photo to templates',
                              onPressed: _isImporting ? null : _startRawImport,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _templateCards.length,
                    itemBuilder: (_, i) {
                      final card = _templateCards[i];
                      return DrawingCardWidget(
                        entry: card.entry,
                        label: card.label,
                        emoji: card.emoji,
                        hasThumbnail: card.hasThumbnail,
                        onTap: () => _openEntry(card.entry),
                        onDelete: card.entry.type == DrawingType.template
                            ? null
                            : () => _confirmDelete(card),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── My Uploads ─────────────────────────────────────
                  const Text(
                    '📷 My Uploads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _UploadAddButton(
                          isLoading: _isUploading,
                          onTap: _isUploading ? null : _startUpload,
                        ),
                        ..._uploadCards.map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: SizedBox(
                              width: 90,
                              child: DrawingCardWidget(
                                entry: card.entry,
                                label: card.label,
                                hasThumbnail: card.hasThumbnail,
                                onTap: () => _openEntry(card.entry),
                                onDelete: () => _confirmDelete(card),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

/// Holds pre-computed card display data to avoid repeated file I/O in build.
class _CardData {
  final DrawingEntry entry;
  final String label;
  final String? emoji;
  final bool hasThumbnail;
  _CardData({
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
  });
}

class _UploadAddButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _UploadAddButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.green.shade300, width: 2),
          borderRadius: BorderRadius.circular(14),
          color: Colors.green.shade50,
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 28, color: Colors.green.shade400),
                  const SizedBox(height: 4),
                  Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A dialog that requires the user to solve a simple addition problem
/// before permanently deleting a user-owned drawing entry.
///
/// The math gate (sum of two random numbers 5–15) is trivially easy for
/// adults but reliably unsolvable by children aged 3–5.
class DeleteConfirmationDialog extends StatefulWidget {
  final DrawingEntry entry;
  final VoidCallback onConfirmed;

  const DeleteConfirmationDialog({
    super.key,
    required this.entry,
    required this.onConfirmed,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  late final int _a;
  late final int _b;
  late final int _answer;
  final _controller = TextEditingController();
  String? _errorText;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 5 + rng.nextInt(11); // 5–15
    _b = 5 + rng.nextInt(11); // 5–15
    _answer = _a + _b;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final input = int.tryParse(_controller.text.trim());
    if (input != _answer) {
      setState(() {
        _errorText = 'Wrong answer, try again';
        _controller.clear();
      });
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await DrawingRepository.deleteEntry(widget.entry);
      widget.onConfirmed();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete this image?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What is $_a + $_b?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Your answer',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _onDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
