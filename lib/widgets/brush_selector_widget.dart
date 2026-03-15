import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';

/// Row of 5 large brush selector buttons. No sliders — tap to select.
class BrushSelectorWidget extends StatelessWidget {
  final BrushType selectedBrush;
  final ValueChanged<BrushType> onBrushSelected;

  const BrushSelectorWidget({
    super.key,
    required this.selectedBrush,
    required this.onBrushSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: BrushType.values.map((type) => _BrushButton(
        type: type,
        isSelected: type == selectedBrush,
        onTap: () => onBrushSelected(type),
      )).toList(),
    );
  }
}

class _BrushButton extends StatelessWidget {
  final BrushType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushButton({required this.type, required this.isSelected, required this.onTap});

  static const _icons = {
    BrushType.pencil:   Icons.edit,
    BrushType.marker:   Icons.brush,
    BrushType.airbrush: Icons.blur_on,
    BrushType.pattern:  Icons.star,
    BrushType.splatter: Icons.scatter_plot,
  };

  static const _labels = {
    BrushType.pencil:   'Pencil',
    BrushType.marker:   'Marker',
    BrushType.airbrush: 'Air',
    BrushType.pattern:  'Stars',
    BrushType.splatter: 'Splat',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icons[type]!, size: 28, color: isSelected ? Colors.deepPurple : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              _labels[type]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
