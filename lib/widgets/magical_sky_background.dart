import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen magical sky gradient with drifting sparkle particles.
///
/// Inserted at the root via MaterialApp.builder so every route inherits
/// the background. All per-screen BoxDecoration gradient wrappers are
/// removed when this widget is active.
class MagicalSkyBackground extends StatefulWidget {
  final Widget child;
  const MagicalSkyBackground({super.key, required this.child});

  @override
  State<MagicalSkyBackground> createState() => _MagicalSkyBackgroundState();
}

class _MagicalSkyBackgroundState extends State<MagicalSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Gradient layer ──────────────────────────────────────────────
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.magicalSky),
        ),

        // ── Sparkle layer (non-interactive) ────────────────────────────
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _SparklePainter(_ctrl.value),
              size: Size.infinite,
            ),
          ),
        ),

        // ── App content ─────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

// ── Sparkle Painter ──────────────────────────────────────────────────────────

class _SparklePainter extends CustomPainter {
  final double t; // 0.0 → 1.0, repeating animation value

  _SparklePainter(this.t);

  // 12 particles — each has a fixed seed that determines base position,
  // drift amplitude, speed multiplier, colour index, and opacity range.
  static const _particles = [
    _Particle(sx: 0.12, sy: 0.08, ax: 0.06, ay: 0.04, sp: 1.0, ci: 0, oMin: 0.5),
    _Particle(sx: 0.30, sy: 0.22, ax: 0.04, ay: 0.07, sp: 0.7, ci: 1, oMin: 0.4),
    _Particle(sx: 0.55, sy: 0.05, ax: 0.05, ay: 0.05, sp: 1.3, ci: 2, oMin: 0.6),
    _Particle(sx: 0.78, sy: 0.15, ax: 0.07, ay: 0.03, sp: 0.9, ci: 0, oMin: 0.45),
    _Particle(sx: 0.90, sy: 0.35, ax: 0.03, ay: 0.06, sp: 1.1, ci: 1, oMin: 0.5),
    _Particle(sx: 0.20, sy: 0.50, ax: 0.08, ay: 0.04, sp: 0.8, ci: 2, oMin: 0.4),
    _Particle(sx: 0.65, sy: 0.42, ax: 0.04, ay: 0.08, sp: 1.2, ci: 0, oMin: 0.55),
    _Particle(sx: 0.40, sy: 0.70, ax: 0.06, ay: 0.05, sp: 1.0, ci: 1, oMin: 0.4),
    _Particle(sx: 0.85, sy: 0.62, ax: 0.05, ay: 0.06, sp: 0.85, ci: 2, oMin: 0.5),
    _Particle(sx: 0.10, sy: 0.80, ax: 0.07, ay: 0.03, sp: 1.15, ci: 0, oMin: 0.45),
    _Particle(sx: 0.50, sy: 0.90, ax: 0.04, ay: 0.07, sp: 0.95, ci: 1, oMin: 0.6),
    _Particle(sx: 0.72, sy: 0.82, ax: 0.06, ay: 0.04, sp: 1.05, ci: 2, oMin: 0.4),
  ];

  static const _colors = [
    AppColors.gradientStart, // mint
    AppColors.gradientMid,   // ice-blue
    AppColors.gradientEnd,   // candy-pink
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final phase = t * p.sp * math.pi * 2;

      final x = (p.sx + math.sin(phase + i) * p.ax) * size.width;
      final y = (p.sy + math.cos(phase * 0.7 + i) * p.ay) * size.height;
      final opacity = p.oMin + (1.0 - p.oMin) * (0.5 + 0.5 * math.sin(phase + i * 0.8));
      final radius = 3.0 + 3.5 * math.sin(phase * 0.5 + i).abs();

      paint
        ..color = _colors[p.ci].withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

class _Particle {
  final double sx;   // seed x (0–1 fraction of width)
  final double sy;   // seed y (0–1 fraction of height)
  final double ax;   // x drift amplitude (fraction of width)
  final double ay;   // y drift amplitude (fraction of height)
  final double sp;   // speed multiplier
  final int ci;      // colour index (0–2)
  final double oMin; // minimum opacity

  const _Particle({
    required this.sx, required this.sy,
    required this.ax, required this.ay,
    required this.sp, required this.ci,
    required this.oMin,
  });
}
