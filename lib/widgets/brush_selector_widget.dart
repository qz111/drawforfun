import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Row of brush selector tiles. Tap to select; selected tile gets a clay
/// shadow and accent border to communicate state clearly at a glance.
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
      children: BrushType.values.map((type) => _BrushTile(
        type: type,
        isSelected: type == selectedBrush,
        onTap: () => onBrushSelected(type),
      )).toList(),
    );
  }
}

class _BrushTile extends StatelessWidget {
  final BrushType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushTile({required this.type, required this.isSelected, required this.onTap});

  static const _icons = {
    BrushType.pencil:   Icons.edit,
    BrushType.marker:   Icons.brush,
    BrushType.airbrush: Icons.blur_on,
    BrushType.pattern:  Icons.star,
    BrushType.splatter: Icons.scatter_plot,
    BrushType.eraser:   Icons.auto_fix_normal,
  };

  static const _labels = {
    BrushType.pencil:   'Pencil',
    BrushType.marker:   'Marker',
    BrushType.airbrush: 'Air',
    BrushType.pattern:  'Stars',
    BrushType.splatter: 'Splat',
    BrushType.eraser:   'Erase',
  };

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? AppShadows.clay(AppColors.accentPrimary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icons[type]!,
              size: 28,
              color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[type]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
