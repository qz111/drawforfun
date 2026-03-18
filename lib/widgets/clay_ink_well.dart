import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Wraps any widget with a clay squish press animation: scales to 0.94 on
/// press, then springs back to 1.0 with physics-driven bounce on release.
///
/// Use this around every tappable surface to achieve the "physical toy" feel
/// required by the DrawForFun Claymorphism design language.
class ClayInkWell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClayInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ClayInkWell> createState() => _ClayInkWellState();
}

class _ClayInkWellState extends State<ClayInkWell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  // Spring parameters: stiffness 300 + damping 20 gives a quick, satisfying pop
  static const _spring = SpringDescription(mass: 1, stiffness: 300, damping: 20);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      // No reverseDuration — release is physics-driven, not time-driven
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _ctrl.stop(); // cancel any in-flight spring before compressing
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) => _springBack();

  void _onTapCancel() => _springBack();

  void _springBack() {
    // Animate from current compressed value back to 0.0 (scale = 1.0)
    // using spring physics for a satisfying "pop" feel.
    _ctrl.animateWith(
      SpringSimulation(_spring, _ctrl.value, 0.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
