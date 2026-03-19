import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Color swatch picker. Supports horizontal Wrap (default) and vertical ListView.
class PaletteWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final Axis axis;

  const PaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      // Vertical: single-column ListView, 24 swatches only (no eraser sentinel).
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ColorPalette.swatches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final color = ColorPalette.swatches[index];
          return Center(
            child: _ColorSwatch(
              color: color,
              isSelected: color == selectedColor,
              onTap: () => onColorSelected(color),
            ),
          );
        },
      );
    }

    // Horizontal default: Wrap with eraser sentinel appended.
    final allColors = [...ColorPalette.swatches, ColorPalette.eraser];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allColors.map((color) => _ColorSwatch(
        color: color,
        isSelected: color == selectedColor,
        onTap: () => onColorSelected(color),
      )).toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade400,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
      ),
    );
  }
}
