import 'dart:ui';
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Always-visible frosted glass vertical rail showing one icon tile per brush type.
/// Tapping the active brush calls [onToggleStrip]; tapping another calls [onBrushSelected].
class BrushRailWidget extends StatelessWidget {
  final BrushType selectedBrush;
  /// Whether the options strip is currently open. Passed through to the parent
  /// so it can show/hide the OptionsStripWidget; the rail itself does not change
  /// its appearance based on this value.
  final bool isStripOpen;
  final ValueChanged<BrushType> onBrushSelected;
  final VoidCallback onToggleStrip;

  const BrushRailWidget({
    super.key,
    required this.selectedBrush,
    required this.isStripOpen,
    required this.onBrushSelected,
    required this.onToggleStrip,
  });

  static const _icons = {
    BrushType.pencil:   Icons.edit,
    BrushType.marker:   Icons.brush,
    BrushType.airbrush: Icons.blur_on,
    BrushType.pattern:  Icons.star,
    BrushType.splatter: Icons.scatter_plot,
    BrushType.eraser:   Icons.auto_fix_normal,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        bottomLeft: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 64,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.78),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
            boxShadow: AppShadows.frosted,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BrushType.values.map((type) {
              final isSelected = type == selectedBrush;
              return _BrushTile(
                icon: _icons[type]!,
                isSelected: isSelected,
                onTap: isSelected ? onToggleStrip : () => onBrushSelected(type),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BrushTile extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushTile({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.18)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
