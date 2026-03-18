import 'package:flutter/material.dart';

/// Three-tile S/M/L eraser size selector.
/// Appears in the coloring screen's bottom toolbar Row 2 when the Eraser brush is active.
/// Styled to match ThemePickerWidget's tile layout and deepPurple selection highlight.
class EraserSizePickerWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSizeSelected;

  const EraserSizePickerWidget({
    super.key,
    required this.selectedIndex,
    required this.onSizeSelected,
  });

  // Visual circle diameters for S / M / L — proportional to eraser stroke widths.
  static const _circleDiameters = [16.0, 28.0, 44.0];
  static const _labels = ['S', 'M', 'L'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _SizeTile(
            label: _labels[i],
            circleDiameter: _circleDiameters[i],
            isSelected: i == selectedIndex,
            onTap: () => onSizeSelected(i),
          ),
        )),
      ),
    );
  }
}

class _SizeTile extends StatelessWidget {
  final String label;
  final double circleDiameter;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeTile({
    required this.label,
    required this.circleDiameter,
    required this.isSelected,
    required this.onTap,
  });

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
            Container(
              width: circleDiameter,
              height: circleDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
