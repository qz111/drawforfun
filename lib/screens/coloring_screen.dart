import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../line_art/line_art_engine.dart';
import '../palette/palette_widget.dart';
import '../save/save_manager.dart';
import '../templates/animal_template.dart';
import '../widgets/brush_selector_widget.dart';
import 'template_screen.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();

  /// Photo-converted line art bytes (from LineArtEngine). Null when a template is active.
  Uint8List? _lineArtBytes;

  /// Active animal template asset path. Null when photo line art is active or canvas is blank.
  String? _activeTemplatePath;

  bool _isProcessing = false;

  /// True when the canvas has any content worth saving or switching away from.
  bool get _canvasHasContent =>
      _controller.strokes.isNotEmpty ||
      _lineArtBytes != null ||
      _activeTemplatePath != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndConvertPhoto() async {
    // withData: true is required on Windows/desktop — bytes is null otherwise.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      // Run heavy Sobel computation in a background isolate so the spinner renders.
      final lineArt = await compute(LineArtEngine.convert, result.files.single.bytes!);
      if (mounted) {
        setState(() {
          _lineArtBytes = lineArt;
          _activeTemplatePath = null; // photo overlay replaces any active template
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveArtwork() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;

    final path = await SaveManager.saveToAppDocuments(bytes);

    // Gallery save (iOS only) failures are silent — in-app save is the primary path.
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

  /// Entry point for the Templates toolbar button.
  Future<void> _onTemplatesTapped() async {
    if (_canvasHasContent) {
      await _showSwitchTemplateDialog();
    } else {
      await _navigateToTemplateScreen();
    }
  }

  /// Shows a dialog offering to save, discard, or cancel before switching templates.
  Future<void> _showSwitchTemplateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch template?'),
        content: const Text('You have a drawing in progress.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveArtwork();
              if (mounted) await _navigateToTemplateScreen();
            },
            child: const Text('Save & Switch'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _navigateToTemplateScreen();
            },
            child: const Text('Discard & Switch', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Pushes TemplateScreen and applies the selection if one is made.
  Future<void> _navigateToTemplateScreen() async {
    final template = await Navigator.push<AnimalTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const TemplateScreen()),
    );
    if (template != null && mounted) {
      _applyTemplate(template);
    }
  }

  /// Clears strokes and sets the active template, nulling photo overlay.
  void _applyTemplate(AnimalTemplate template) {
    _controller.clear();
    setState(() {
      _lineArtBytes = null;
      _activeTemplatePath = template.assetPath;
    });
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
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _isProcessing ? null : _onTemplatesTapped,
            tooltip: 'Templates',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickAndConvertPhoto,
            tooltip: 'Load photo',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _controller.undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isProcessing ? null : () => _showClearDialog(context),
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _isProcessing ? null : _saveArtwork,
            tooltip: 'Save',
          ),
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
                          lineArtAssetPath: _activeTemplatePath,
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
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text('This will erase everything. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              setState(() {
                _lineArtBytes = null;       // bug fix: was not clearing photo overlay
                _activeTemplatePath = null;  // clear template overlay too
              });
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
