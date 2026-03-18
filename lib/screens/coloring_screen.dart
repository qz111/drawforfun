import 'dart:ui';

import 'package:drawforfun/brushes/brush_type.dart';

import '../widgets/clay_ink_well.dart';
import '../widgets/eraser_size_picker_widget.dart';
import '../widgets/theme_picker_widget.dart';
import 'package:flutter/material.dart';
import '../brushes/stroke.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../palette/palette_widget.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../save/save_manager.dart';
import '../theme/app_theme.dart';
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

  /// Shared back-navigation handler — called by both PopScope (hardware/gesture
  /// back) and the floating back button tap. Runs _autoSave then pops.
  Future<void> _handleBack() async {
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    await _autoSave();
    if (mounted) {
      setState(() => _isSaving = false);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
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

                // Bottom panel removed — now a DraggableScrollableSheet in the Stack
              ],
            ),

            // ── Collapsible frosted bottom sheet ────────────────────────────────
            DraggableScrollableSheet(
              initialChildSize: 0.22,
              minChildSize: 0.08,
              maxChildSize: 0.38,
              snap: true,
              snapSizes: const [0.08, 0.22, 0.38],
              builder: (context, _) {
                // _ is the sheet's own ScrollController — unused since sheet content
                // is not itself scrollable. Named _ to satisfy the linter.
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.78),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: AppShadows.frosted,
                      ),
                      child: ListenableBuilder(
                        listenable: _controller,
                        builder: (_, __) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag handle
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 6),
                              child: Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 0, 0, 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Brush selector row
                            BrushSelectorWidget(
                              selectedBrush: _controller.activeBrushType,
                              onBrushSelected: _controller.setActiveBrush,
                            ),
                            const SizedBox(height: 10),

                            // Palette / theme / eraser picker — unchanged logic
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _controller.activeBrushType == BrushType.eraser
                                  ? EraserSizePickerWidget(
                                      key: const ValueKey('eraser'),
                                      selectedIndex: _controller.activeThemeIndex,
                                      onSizeSelected: _controller.setActiveTheme,
                                    )
                                  : _isThemeBrush(_controller.activeBrushType)
                                      ? ThemePickerWidget(
                                          key: const ValueKey('theme'),
                                          brushType: _controller.activeBrushType,
                                          selectedIndex: _controller.activeThemeIndex,
                                          onThemeSelected: _controller.setActiveTheme,
                                        )
                                      : PaletteWidget(
                                          key: const ValueKey('palette'),
                                          selectedColor: _controller.activeColor,
                                          onColorSelected: _controller.setActiveColor,
                                        ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Floating back button (top-left) ─────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16),
                  child: _FloatingCircleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: _isSaving ? null : _handleBack,
                    tooltip: 'Back',
                  ),
                ),
              ),
            ),

            // ── Floating action buttons (top-right) ─────────────────────────────
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FloatingCircleButton(
                        icon: Icons.undo,
                        onTap: _isSaving ? null : _controller.undo,
                        tooltip: 'Undo',
                      ),
                      const SizedBox(width: 8),
                      _FloatingCircleButton(
                        icon: Icons.delete_outline,
                        onTap: _isSaving ? null : () => _showClearDialog(context),
                        tooltip: 'Clear',
                      ),
                      const SizedBox(width: 8),
                      _FloatingCircleButton(
                        icon: Icons.save_alt,
                        onTap: _isSaving ? null : _saveToGallery,
                        tooltip: 'Save',
                      ),
                    ],
                  ),
                ),
              ),
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
                const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

   bool _isThemeBrush(BrushType type) =>
      type == BrushType.airbrush || type == BrushType.pattern;
}

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.soft(AppColors.accentPrimary),
              ),
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
