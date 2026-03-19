import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Eraser size selector. Supports horizontal (default) and vertical layouts.
class EraserSizePickerWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSizeSelected;
  final Axis axis;

  const EraserSizePickerWidget({
    super.key,
    required this.selectedIndex,
    required this.onSizeSelected,
    this.axis = Axis.horizontal,
  });

  static const _circleDiameters = [16.0, 28.0, 44.0];
  static const _labels = ['S', 'M', 'L'];

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    return SingleChildScrollView(
      scrollDirection: axis,
      child: isVertical
          ? Column(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _SizeTile(
                  label: _labels[i],
                  circleDiameter: _circleDiameters[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onSizeSelected(i),
                  width: 56,
                  height: 64,
                ),
              )),
            )
          : Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _SizeTile(
                  label: _labels[i],
                  circleDiameter: _circleDiameters[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onSizeSelected(i),
                  width: 60,
                  height: 70,
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
  final double width;
  final double height;

  const _SizeTile({
    required this.label,
    required this.circleDiameter,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        constraints: BoxConstraints(maxHeight: height),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected ? AppShadows.clay(AppColors.accentPrimary) : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circleDiameter,
                height: circleDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
