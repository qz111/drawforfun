import 'dart:ui';
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../canvas/canvas_controller.dart';
import '../palette/palette_widget.dart';
import '../theme/app_theme.dart';
import 'eraser_size_picker_widget.dart';
import 'theme_picker_widget.dart';

/// Animated frosted glass options strip.
/// Slides in from the right (behind the brush rail) when [isVisible] is true.
/// Content is determined by [activeBrush] — palette, theme picker, or eraser sizes.
class OptionsStripWidget extends StatelessWidget {
  final bool isVisible;
  final BrushType activeBrush;
  final CanvasController controller;

  const OptionsStripWidget({
    super.key,
    required this.isVisible,
    required this.activeBrush,
    required this.controller,
  });

  bool get _isThemeBrush =>
      activeBrush == BrushType.airbrush || activeBrush == BrushType.pattern;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: const ValueKey('options_strip_ignore_pointer'),
      ignoring: !isVisible,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(1.0, 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 72,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.65),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                  boxShadow: AppShadows.frosted,
                ),
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (_, __) => _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (activeBrush == BrushType.eraser) {
      return EraserSizePickerWidget(
        axis: Axis.vertical,
        selectedIndex: controller.activeThemeIndex,
        onSizeSelected: controller.setActiveTheme,
      );
    }
    if (_isThemeBrush) {
      return ThemePickerWidget(
        axis: Axis.vertical,
        brushType: activeBrush,
        selectedIndex: controller.activeThemeIndex,
        onThemeSelected: controller.setActiveTheme,
      );
    }
    // Pencil, marker, splatter — color palette.
    return PaletteWidget(
      axis: Axis.vertical,
      selectedColor: controller.activeColor,
      onColorSelected: controller.setActiveColor,
    );
  }
}
