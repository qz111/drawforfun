import 'package:flutter/material.dart';
import '../brushes/brush_theme.dart';
import '../brushes/brush_type.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Scrollable list of 10 theme/style tiles.
/// Supports horizontal (default, bottom bar) and vertical (options strip) layouts.
class ThemePickerWidget extends StatelessWidget {
  final BrushType brushType;
  final int selectedIndex;
  final ValueChanged<int> onThemeSelected;
  final Axis axis;

  const ThemePickerWidget({
    super.key,
    required this.brushType,
    required this.selectedIndex,
    required this.onThemeSelected,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final isAirbrush = brushType == BrushType.airbrush;
    final isVertical = axis == Axis.vertical;
    const count = 10;
    final double emojiSize = isVertical ? 20.0 : 22.0;

    Widget list = ListView.separated(
      scrollDirection: axis,
      padding: isVertical
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 4),
      itemCount: count,
      separatorBuilder: (_, __) =>
          isVertical ? const SizedBox(height: 6) : const SizedBox(width: 6),
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

        final double tileW = isVertical ? 56 : 80;
        final double tileH = isVertical ? 56 : 64;

        return ClayInkWell(
          onTap: () => onThemeSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: tileW,
            height: tileH,
            constraints: BoxConstraints(maxWidth: tileW, maxHeight: tileH),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: selected ? AppColors.accentPrimary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected ? AppShadows.clay(AppColors.accentPrimary) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: emojiSize)),
                // Label dropped in vertical mode — too narrow for 56px width.
                if (!isVertical) ...[
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
              ],
            ),
          ),
        );
      },
    );

    // Horizontal layout needs a fixed height; vertical is unconstrained.
    return isVertical ? list : SizedBox(height: 64, child: list);
  }
}
