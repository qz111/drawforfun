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
