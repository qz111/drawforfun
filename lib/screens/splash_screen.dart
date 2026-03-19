import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'main_menu_screen.dart';

/// Splash screen shown for exactly 3 s on launch.
///
/// Flow:
///   1. Fades in all content over 800 ms (ease-out curve).
///   2. After a strict 3-second [Future.delayed], cross-fades into
///      [MainMenuScreen] via [Navigator.pushReplacement].
///
/// Asset swap (when PNG is ready):
///   Replace [_FoxCharacterPlaceholder] with:
///   ```dart
///   Image.asset('assets/icon/app_icon.png', width: 220, height: 220)
///   ```
///   Then register the asset in pubspec.yaml under flutter › assets.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Strict 3-second timer — fires once, checks [mounted] for safety.
    Future.delayed(const Duration(seconds: 3), _goToMainMenu);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToMainMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        // 500 ms cross-fade — enter ease-in, exit completes first (shorter).
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent — MagicalSkyBackground (applied in app builder) shows through.
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── App icon character ─────────────────────────────────────
                const _FoxCharacterPlaceholder(),
                const SizedBox(height: 36),

                // ── Rainbow title ──────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFF6B6B), // coral-red
                      Color(0xFFFFB347), // tangerine
                      Color(0xFFFFD700), // gold
                      Color(0xFF34D399), // mint
                      Color(0xFF60A5FA), // sky-blue
                      Color(0xFFC084FC), // lavender
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'Magical Coloring\nWorld',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: Colors.white, // replaced by ShaderMask
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tagline ────────────────────────────────────────────────
                Text(
                  'Draw  •  Color  •  Dream',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fox Character Placeholder ─────────────────────────────────────────────────

/// Clay-style character placeholder (220 × 220 pt).
///
/// ════════════════════════════════════════════════════════════════════════
/// ASSET CREATOR BRIEF — final art replaces this widget entirely
/// ════════════════════════════════════════════════════════════════════════
///
/// DELIVERABLE: 1024 × 1024 px PNG, sRGB, transparent background.
/// PATH: assets/icon/app_icon.png  (also used by flutter_launcher_icons)
///
/// CONCEPT ─────────────────────────────────────────────────────────────
/// A chibi-cute fox in a playful 3/4-front pose, holding an oversized
/// glowing rainbow paint marker. Claymorphism aesthetic — all forms have
/// soft 3-D clay depth (bright top-highlight ~35 %, deep shadow ~25 %).
///
/// ICON BACKGROUND (fills the 1024 × 1024 canvas)
///   • Circular mask (the icon shape) filled with a radial gradient:
///       centre: sky-blue  #C8F0FF  →  edge: soft lavender  #D8BFFF
///   • Subtle mint bloom (#AAFFD4) glowing from lower-right at ~30 % opacity.
///   • 3 diagonal rainbow streak arcs sweeping lower-left → upper-right,
///     angled ~30 ° from horizontal; wispy brush-stroke texture, 15 % opacity.
///     Colour order: #FF6B6B › #FFB347 › #FFD700 › #34D399 › #60A5FA › #C084FC
///
/// FOX BODY ────────────────────────────────────────────────────────────
///   • Sitting pose, body occupies ~75 % of canvas height.
///   • Primary fur: warm amber/tangerine  #FF9A3C
///   • Underbelly, inner ears, cheek ovals: creamy white  #FFF5E0
///   • Ear tips and tail tip: deep coral  #FF5252
///   • Nose: small rounded triangle in warm brown  #A0522D
///   • Tail wraps around the left side of the body, visible behind the fox.
///
/// EYES
///   • Large round eyes, each ~14 % of canvas width.
///   • Iris: bright indigo-violet  #7C6FF7  (matches app accent colour)
///   • Pupil: deep navy circle at centre.
///   • Specular dot: white, upper-right quadrant of iris, ~25 % of iris radius.
///   • Subtle lash-line at top of iris (2 px dark curve).
///
/// MARKER (PAINT TOOL) ─────────────────────────────────────────────────
///   • Oversized chibi prop: ~40 % of character height.
///   • Held in right paw, angled ~15 ° from vertical, tip pointing down-right.
///   • Barrel: glossy white cylinder with a full-length vertical rainbow stripe.
///   • Cap end (top): navy blue  #1E40AF, rounded cap ring.
///   • Tip: tapered felt-tip in gold  #FFD700.
///   • Paint drip: single teardrop drip in magenta  #FF2D78, falling from tip.
///   • Glow aura: soft radial bloom around the tip in rainbow hues, blur 24 px,
///     30 % opacity — as if the marker is magically luminous.
///
/// EXPORT NOTES ────────────────────────────────────────────────────────
///   • No rounded corners — flutter_launcher_icons applies platform masks.
///   • Minimum clear space: 5 % on all sides within the 1024 canvas.
///   • Export a second version cropped to circular mask for preview use.
class _FoxCharacterPlaceholder extends StatelessWidget {
  const _FoxCharacterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFC8F0FF), // sky-blue centre
            Color(0xFFD8BFFF), // lavender edge
          ],
          center: Alignment(-0.2, -0.25),
          radius: 0.85,
        ),
        boxShadow: AppShadows.clay(AppColors.accentPrimary),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background rainbow arcs
          const CustomPaint(
            size: Size(220, 220),
            painter: _RainbowArcPainter(),
          ),

          // Fox silhouette (simplified clay shapes)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Head
              Container(
                width: 104,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A3C),
                  borderRadius: BorderRadius.circular(AppRadius.outer),
                  boxShadow: AppShadows.soft(const Color(0xFFFF9A3C)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_EyeDot(), SizedBox(width: 22), _EyeDot()],
                ),
              ),
              const SizedBox(height: 6),
              // Body
              Container(
                width: 82,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A3C),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadows.soft(const Color(0xFFFF9A3C)),
                ),
              ),
            ],
          ),

          // "ART PENDING" label
          Positioned(
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                'ART PENDING',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eye dot ───────────────────────────────────────────────────────────────────

class _EyeDot extends StatelessWidget {
  const _EyeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.accentPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
      // White specular dot in upper-right quadrant
      child: const Align(
        alignment: Alignment(0.5, -0.5),
        child: SizedBox(
          width: 5,
          height: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rainbow arc background painter ───────────────────────────────────────────

/// Paints 6 concentric wispy rainbow arcs to suggest the icon background streaks.
class _RainbowArcPainter extends CustomPainter {
  const _RainbowArcPainter();

  static const _arcColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFFFFD700),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFC084FC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < _arcColors.length; i++) {
      final paint = Paint()
        ..color = _arcColors[i].withValues(alpha: 0.22)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final radius = 48.0 + i * 13;
      // Arc sweeps from ~210° to ~330° (lower-left quadrant area)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + 18, cy + 18), radius: radius),
        -2.5, // startAngle (radians, ~−143°)
        1.7,  // sweepAngle (radians, ~97°)
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainbowArcPainter _) => false;
}
