import 'package:flutter/material.dart';
import '../brushes/stroke.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../palette/palette_widget.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../save/save_manager.dart';
import '../widgets/brush_selector_widget.dart';

class ColoringScreen extends StatefulWidget {
  final DrawingEntry entry;

  const ColoringScreen({super.key, required this.entry});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedStrokes();
  }

  /// Loads previously saved strokes from disk in the background.
  /// Does nothing if no strokes.json exists for this entry.
  Future<void> _loadSavedStrokes() async {
    final strokesJson = await DrawingRepository.loadStrokes(widget.entry);
    if (strokesJson.isNotEmpty && mounted) {
      _controller.loadStrokes(strokesJson.map(Stroke.fromJson).toList());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Persists current strokes (JSON) and captures a thumbnail PNG.
  /// Called automatically when the user navigates back.
  Future<void> _autoSave() async {
    await DrawingRepository.saveStrokes(
        widget.entry, _controller.strokesToJson());
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes != null) {
      await DrawingRepository.saveThumbnail(widget.entry, bytes);
    }
  }

  /// Saves the current canvas as a PNG to the device photo gallery.
  /// On Windows this is a silent no-op.
  Future<void> _saveToGallery() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;
    await SaveManager.saveToGallery(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to gallery!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context); // capture before await
        setState(() => _isSaving = true);
        await _autoSave();
        if (mounted) {
          setState(() => _isSaving = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text(
            'Draw For Fun',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _controller.undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : () => _showClearDialog(context),
              tooltip: 'Clear',
            ),
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _isSaving ? null : _saveToGallery,
              tooltip: 'Save to gallery',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // ── Canvas ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CanvasStackWidget(
                          controller: _controller,
                          lineArtAssetPath: widget.entry.overlayAssetPath,
                          // Raw imports are opaque photos — render as background
                          // so strokes drawn on top are visible.
                          lineArtFilePath: widget.entry.type != DrawingType.rawImport
                              ? widget.entry.overlayFilePath
                              : null,
                          backgroundFilePath: widget.entry.type == DrawingType.rawImport
                              ? widget.entry.overlayFilePath
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom Panel ─────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) => BrushSelectorWidget(
                          selectedBrush: _controller.activeBrushType,
                          onBrushSelected: _controller.setActiveBrush,
                        ),
                      ),
                      const SizedBox(height: 10),
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

            // Auto-save overlay — dims screen and shows spinner while saving
            if (_isSaving)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text(
            'This will erase your strokes. The line art stays.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clear(); // strokes only — overlay intentionally kept
              Navigator.pop(ctx);
            },
            child:
                const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
