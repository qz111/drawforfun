import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../line_art/line_art_engine.dart';
import '../palette/palette_widget.dart';
import '../save/save_manager.dart';
import '../widgets/brush_selector_widget.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();
  Uint8List? _lineArtBytes;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndConvertPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _isProcessing = true);
    final lineArt = await LineArtEngine.convert(result.files.single.bytes!);
    setState(() {
      _lineArtBytes = lineArt;
      _isProcessing = false;
    });
  }

  Future<void> _saveArtwork() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;

    // Save in-app
    final path = await SaveManager.saveToAppDocuments(bytes);

    // Save to device gallery (iOS only; no-op on Windows)
    await SaveManager.saveToGallery(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Saved!' : 'Save failed'),
          backgroundColor: path != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('Draw For Fun', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.photo_library), onPressed: _pickAndConvertPhoto, tooltip: 'Load photo'),
          IconButton(icon: const Icon(Icons.undo), onPressed: _controller.undo, tooltip: 'Undo'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _showClearDialog(context), tooltip: 'Clear'),
          IconButton(icon: const Icon(Icons.save_alt), onPressed: _saveArtwork, tooltip: 'Save'),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : CanvasStackWidget(
                          controller: _controller,
                          lineArtBytes: _lineArtBytes,
                        ),
                ),
              ),
            ),
          ),

          // ── Bottom Panel ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brush selector
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => BrushSelectorWidget(
                    selectedBrush: _controller.activeBrushType,
                    onBrushSelected: _controller.setActiveBrush,
                  ),
                ),
                const SizedBox(height: 10),
                // Color palette
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => PaletteWidget(
                    selectedColor: _controller.activeColor,
                    onColorSelected: _controller.setActiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text('This will erase everything. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
