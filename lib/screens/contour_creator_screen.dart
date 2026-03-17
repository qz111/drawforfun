import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

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
  ui.Image? backgroundImage;

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

  static final Paint _pencilPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _eraserPaint = Paint()
    ..blendMode = BlendMode.clear
    ..strokeWidth = 24.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

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
      _drawStroke(canvas, stroke, _pencilPaint);
    }

    // 3. In-progress pencil stroke (if pencil tool active).
    if (activeTool == ContourTool.pencil && currentStroke != null) {
      _drawStroke(canvas, currentStroke!, _pencilPaint);
    }

    // 4. Committed eraser strokes.
    for (final stroke in eraserStrokes) {
      _drawStroke(canvas, stroke, _eraserPaint);
    }

    // 5. In-progress eraser stroke (if eraser tool active).
    if (activeTool == ContourTool.eraser && currentStroke != null) {
      _drawStroke(canvas, currentStroke!, _eraserPaint);
    }

    canvas.restore();
  }

  /// Always return true — simplest correct approach for a drawing canvas.
  @override
  bool shouldRepaint(ContourCreatorPainter oldDelegate) => true;
}

// ── Screen placeholder (to be completed in Task 6) ───────────────────────────

class ContourCreatorScreen extends StatefulWidget {
  const ContourCreatorScreen({
    super.key,
    this.remixSourcePath,
    this.remixAssetPath,
  });

  final String? remixSourcePath;
  final String? remixAssetPath;

  @override
  State<ContourCreatorScreen> createState() => _ContourCreatorScreenState();
}

class _ContourCreatorScreenState extends State<ContourCreatorScreen> {
  final _controller = ContourCreatorController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ContourCreator — WIP')));
  }
}
