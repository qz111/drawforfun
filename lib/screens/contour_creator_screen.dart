import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';
import '../persistence/drawing_repository.dart';
import '../save/save_manager.dart';

// ── Tool enum ─────────────────────────────────────────────────────────────────

enum ContourTool { pencil, eraser }

// ── Controller ───────────────────────────────────────────────────────────────

/// Manages drawing state for the ContourCreatorScreen.
/// Maintains separate lists for pencil and eraser strokes with a unified
/// undo history so that undo removes strokes in the correct order regardless
/// of tool switches.
class ContourCreatorController extends ChangeNotifier {
  final List<Stroke> _pencilStrokes = [];
  final List<Stroke> _eraserStrokes = [];

  /// Unified undo history. Each entry records which list the committed stroke
  /// was appended to, so undo can pop the correct list.
  final List<({bool isPencil})> _history = [];

  ContourTool _activeTool = ContourTool.pencil;
  Stroke? _currentStroke;

  /// Optional base image shown beneath strokes (Remix mode).
  ui.Image? _backgroundImage;
  ui.Image? get backgroundImage => _backgroundImage;
  set backgroundImage(ui.Image? value) {
    _backgroundImage = value;
    notifyListeners();
  }

  List<Stroke> get pencilStrokes => List.unmodifiable(_pencilStrokes);
  List<Stroke> get eraserStrokes => List.unmodifiable(_eraserStrokes);
  Stroke? get currentStroke => _currentStroke;
  ContourTool get activeTool => _activeTool;
  set activeTool(ContourTool value) {
    _activeTool = value;
    notifyListeners();
  }

  /// True when the user has made at least one committed stroke — used to gate
  /// the discard-warning dialog on back-navigation.
  bool get hasUnsavedChanges => _history.isNotEmpty;

  void startStroke(Offset point) {
    // BrushType.pencil is used for all strokes (BrushType has no eraser value).
    // ContourCreatorPainter discriminates tool type by list membership
    // (pencilStrokes vs eraserStrokes), not by Stroke.type.
    _currentStroke = Stroke(
      type: BrushType.pencil,
      color: Colors.black,
      points: [point],
    );
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWithPoint(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    if (_currentStroke!.points.length < 2) {  // discard single-tap noise
      _currentStroke = null;
      notifyListeners();
      return;
    }
    if (_activeTool == ContourTool.pencil) {
      _pencilStrokes.add(_currentStroke!);
      _history.add((isPencil: true));
    } else {
      _eraserStrokes.add(_currentStroke!);
      _history.add((isPencil: false));
    }
    _currentStroke = null;
    notifyListeners();
  }

  /// Removes the most recently committed stroke (pencil or eraser).
  /// No-op if history is empty.
  void undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    if (last.isPencil) {
      _pencilStrokes.removeLast();
    } else {
      _eraserStrokes.removeLast();
    }
    notifyListeners();
  }

  /// Clears all strokes and history. Keeps [backgroundImage].
  void clear() {
    _pencilStrokes.clear();
    _eraserStrokes.clear();
    _history.clear();
    _currentStroke = null;
    notifyListeners();
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

/// Renders pencil strokes, eraser strokes (BlendMode.clear), an optional
/// background image, and the in-progress stroke — all within a saveLayer so
/// that BlendMode.clear cuts through to transparency correctly.
class ContourCreatorPainter extends CustomPainter {
  final List<Stroke> pencilStrokes;
  final List<Stroke> eraserStrokes;
  final Stroke? currentStroke;
  final ContourTool activeTool;
  final ui.Image? backgroundImage;

  ContourCreatorPainter({
    required this.pencilStrokes,
    required this.eraserStrokes,
    required this.currentStroke,
    required this.activeTool,
    required this.backgroundImage,
  });

  /// Draws consecutive point pairs of [stroke] onto [canvas] using [paint].
  /// Strokes with fewer than 2 points are skipped.
  void _drawStroke(Canvas canvas, Stroke stroke, Paint paint) {
    final pts = stroke.points;
    if (pts.length < 2) return;
    for (int i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pencilPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // saveLayer is required so that BlendMode.clear erases within the layer
    // rather than cutting through to the widget background.
    canvas.saveLayer(Offset.zero & size, Paint());

    // 1. Background image (Remix mode) drawn at full canvas size.
    if (backgroundImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      final dst = Offset.zero & size;
      canvas.drawImageRect(backgroundImage!, src, dst, Paint());
    }

    // Note: all pencil strokes are rendered before all eraser strokes regardless
    // of temporal draw order. This is an intentional simplification — temporal
    // interleaving (pencil after eraser after pencil) is not preserved.
    // 2. Committed pencil strokes.
    for (final stroke in pencilStrokes) {
      _drawStroke(canvas, stroke, pencilPaint);
    }

    // 3. In-progress pencil stroke (if pencil tool active).
    if (activeTool == ContourTool.pencil && currentStroke != null) {
      _drawStroke(canvas, currentStroke!, pencilPaint);
    }

    // 4. Committed eraser strokes.
    for (final stroke in eraserStrokes) {
      _drawStroke(canvas, stroke, eraserPaint);
    }

    // 5. In-progress eraser stroke (if eraser tool active).
    if (activeTool == ContourTool.eraser && currentStroke != null) {
      _drawStroke(canvas, currentStroke!, eraserPaint);
    }

    canvas.restore();
  }

  /// Always return true — simplest correct approach for a drawing canvas.
  @override
  bool shouldRepaint(ContourCreatorPainter oldDelegate) => true;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ContourCreatorScreen extends StatefulWidget {
  /// Absolute path to a local image file (upload / rawImport / customTemplate).
  final String? remixSourcePath;

  /// Flutter asset path to a bundled SVG (built-in templates only).
  /// Mutually exclusive with [remixSourcePath]. If both are set,
  /// [remixSourcePath] takes priority.
  final String? remixAssetPath;

  const ContourCreatorScreen({
    super.key,
    this.remixSourcePath,
    this.remixAssetPath,
  });

  @override
  State<ContourCreatorScreen> createState() => _ContourCreatorScreenState();
}

class _ContourCreatorScreenState extends State<ContourCreatorScreen> {
  final _controller = ContourCreatorController();
  final _repaintKey = GlobalKey();
  bool _isSaving = false;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // File-path images don't need canvas size — load immediately after first frame.
    if (widget.remixSourcePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRemixImage());
    }
    // SVG assets need _canvasSize — loading is triggered from the LayoutBuilder callback.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemixImage() async {
    ui.Image? img;
    try {
      if (widget.remixSourcePath != null) {
        final bytes = await File(widget.remixSourcePath!).readAsBytes();
        img = await decodeImageFromList(bytes);
      } else if (widget.remixAssetPath != null) {
        // SVG assets: rasterise via flutter_svg PictureInfo API.
        final sz = _canvasSize;
        if (sz == Size.zero) return; // layout not ready yet
        final loader = SvgAssetLoader(widget.remixAssetPath!);
        final pictureInfo = await vg.loadPicture(loader, null);
        img = await pictureInfo.picture
            .toImage(sz.width.round(), sz.height.round());
        pictureInfo.picture.dispose();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load image — starting with blank canvas'),
        ));
      }
    }
    if (img != null && mounted) {
      _controller.backgroundImage = img; // setter calls notifyListeners(), no setState needed
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await SaveManager.captureCanvas(_repaintKey);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save, try again')),
          );
        }
        return;
      }
      await DrawingRepository.createCustomTemplateEntry(bytes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (!_controller.hasUnsavedChanges) {
          navigator.pop();
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard this template?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text(
            'Template Creator',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              // ── Canvas area ───────────────────────────────────────────
              LayoutBuilder(builder: (context, constraints) {
                // Capture canvas size for SVG rasterisation on first layout.
                final sz = Size(constraints.maxWidth, constraints.maxHeight);
                if (_canvasSize != sz) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _canvasSize != sz) {
                      setState(() => _canvasSize = sz);
                      _loadRemixImage(); // now _canvasSize is set before loading
                    }
                  });
                }
                return GestureDetector(
                  onPanStart: (d) =>
                      _controller.startStroke(d.localPosition),
                  onPanUpdate: (d) =>
                      _controller.addPoint(d.localPosition),
                  onPanEnd: (_) => _controller.endStroke(),
                  onPanCancel: () => _controller.endStroke(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Checkerboard background (decorative — not captured)
                        IgnorePointer(child: _CheckerboardBackground()),
                        // Drawing layer (captured)
                        RepaintBoundary(
                          key: _repaintKey,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, __) => CustomPaint(
                              painter: ContourCreatorPainter(
                                pencilStrokes: _controller.pencilStrokes,
                                eraserStrokes: _controller.eraserStrokes,
                                currentStroke: _controller.currentStroke,
                                activeTool: _controller.activeTool,
                                backgroundImage: _controller.backgroundImage,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // ── Floating left sidebar ─────────────────────────────────
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToolButton(
                            icon: Icons.edit,
                            tooltip: 'Pencil',
                            isActive:
                                _controller.activeTool == ContourTool.pencil,
                            onTap: () => _controller.activeTool =
                                ContourTool.pencil,
                          ),
                          const SizedBox(height: 6),
                          _ToolButton(
                            icon: Icons.auto_fix_normal,
                            tooltip: 'Eraser',
                            isActive:
                                _controller.activeTool == ContourTool.eraser,
                            onTap: () => _controller.activeTool =
                                ContourTool.eraser,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, thickness: 1),
                          ),
                          IgnorePointer(
                            ignoring: !_controller.hasUnsavedChanges,
                            child: Opacity(
                              opacity:
                                  _controller.hasUnsavedChanges ? 1.0 : 0.4,
                              child: _ToolButton(
                                icon: Icons.undo,
                                tooltip: 'Undo',
                                isActive: false,
                                onTap: _controller.undo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          IgnorePointer(
                            ignoring: !_controller.hasUnsavedChanges,
                            child: Opacity(
                              opacity:
                                  _controller.hasUnsavedChanges ? 1.0 : 0.4,
                              child: _ToolButton(
                                icon: Icons.delete_outline,
                                tooltip: 'Clear',
                                isActive: false,
                                onTap: _controller.clear,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CheckerboardPainter());
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 16.0;
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = const Color(0xFFE0E0E0);
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final paint = (r + c).isEven ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
              c * cellSize, r * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter _) => false;
}
