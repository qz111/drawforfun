import 'package:flutter/material.dart';
import '../brushes/brush_theme.dart';
import '../brushes/brush_type.dart';

/// Horizontal scrollable list of 10 theme/style tiles.
/// Shown in place of the color palette when Airbrush or Pattern is active.
/// Stateless — selection state is owned by CanvasController.
class ThemePickerWidget extends StatelessWidget {
  final BrushType brushType;
  final int selectedIndex;
  final ValueChanged<int> onThemeSelected;

  const ThemePickerWidget({
    super.key,
    required this.brushType,
    required this.selectedIndex,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isAirbrush = brushType == BrushType.airbrush;
    const count = 10;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final Color bgColor;
          final String emoji;
          final String label;

          if (isAirbrush) {
            final theme = BrushTheme.airbrushThemes[index];
            bgColor = theme.baseColor;
            emoji = theme.emojis.take(2).join(' ');
            label = theme.label;
          } else {
            final style = BrushTheme.patternStyles[index];
            bgColor = style.backgroundColor;
            emoji = style.emojis.take(2).join(' ');
            label = style.label;
          }

          return GestureDetector(
            onTap: () => onThemeSelected(index),
            child: AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 80,
                height: 64,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.deepPurple : Colors.grey.shade400,
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
