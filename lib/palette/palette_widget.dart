import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Grid of 24 color swatches + eraser. Calls [onColorSelected] on tap.
class PaletteWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const PaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
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
