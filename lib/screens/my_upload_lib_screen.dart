import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../line_art/line_art_engine.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';
import 'template_lib_screen.dart' show DeleteConfirmationDialog;

class MyUploadLibScreen extends StatefulWidget {
  const MyUploadLibScreen({super.key});

  @override
  State<MyUploadLibScreen> createState() => _MyUploadLibScreenState();
}

class _MyUploadLibScreenState extends State<MyUploadLibScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<_CardData> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final entries = await DrawingRepository.listUploadEntries();
    if (mounted) {
      setState(() {
        _cards = entries
            .map((entry) => _CardData(
                  entry: entry,
                  label: _uploadLabel(entry.id),
                  hasThumbnail: File(entry.thumbnailPath).existsSync(),
                ))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    await FileImage(File(entry.thumbnailPath)).evict();
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
              content: Text('Could not convert image — try a different photo'),
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
        await FileImage(File(entry.thumbnailPath)).evict();
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _confirmDelete(_CardData card) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        entry: card.entry,
        onConfirmed: () {
          setState(() => _cards.remove(card));
        },
      ),
    );
  }

  String _uploadLabel(String id) {
    try {
      final date = id.split('_')[1];
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
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          '📷 My Uploads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: const Text('+ Upload'),
                onPressed: _startUpload,
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap a drawing to start coloring',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _cards.isEmpty
                        ? const Center(
                            child: Text(
                              'No uploads yet.\nTap + Upload to add a photo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black45),
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _cards.length,
                              itemBuilder: (_, i) {
                              final card = _cards[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 200,
                                  child: DrawingCardWidget(
                                    entry: card.entry,
                                    label: card.label,
                                    hasThumbnail: card.hasThumbnail,
                                    onTap: () => _openEntry(card.entry),
                                    onDelete: () => _confirmDelete(card),
                                  ),
                                ),
                              );
                            },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CardData {
  final DrawingEntry entry;
  final String label;
  final bool hasThumbnail;
  _CardData({
    required this.entry,
    required this.label,
    required this.hasThumbnail,
  });
}
