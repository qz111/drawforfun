import 'dart:io';
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
    final results = await Future.wait([
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
                              onPressed: _startRawImport,
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
