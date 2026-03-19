import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import 'main_menu_screen.dart';

/// Splash screen shown on launch.
///
/// Plays [_kSplashVideo] once (muted, no controls). When the video ends —
/// or after [_kSafetyTimeout] if initialisation is slow — cross-fades into
/// [MainMenuScreen]. The title and tagline fade in over 800 ms.
///
/// Drop your video at:  assets/splash/splash_video.mp4
const String _kSplashVideo = 'assets/splash/splash_video.mp4';

/// Maximum wait before navigating even if the video hasn't finished.
const Duration _kSafetyTimeout = Duration(seconds: 8);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── Fade-in animation ──────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Video ──────────────────────────────────────────────────────────────────
  late final VideoPlayerController _videoCtrl;
  bool _videoReady = false;
  bool _navigated = false; // guard: navigate only once

  @override
  void initState() {
    super.initState();

    // Fade-in for title + tagline.
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Safety timeout — navigate even if video init is slow or file is missing.
    Future.delayed(_kSafetyTimeout, _goToMainMenu);

    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoCtrl = VideoPlayerController.asset(_kSplashVideo);
    try {
      await _videoCtrl.initialize();
      await _videoCtrl.seekTo(const Duration(seconds: 2)); // skip intro, play s2→end
      await _videoCtrl.setVolume(0); // muted — splash should be silent
      await _videoCtrl.setLooping(false);

      // Listen for natural video completion.
      _videoCtrl.addListener(_onVideoProgress);

      if (mounted) {
        setState(() => _videoReady = true);
        await _videoCtrl.play();
      }
    } catch (_) {
      // Video failed to load — safety timeout will still navigate.
    }
  }

  void _onVideoProgress() {
    final pos = _videoCtrl.value.position;
    final dur = _videoCtrl.value.duration;
    // Trigger navigation within the last 100 ms of the video.
    if (dur > Duration.zero && dur - pos <= const Duration(milliseconds: 100)) {
      _goToMainMenu();
    }
  }

  void _goToMainMenu() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _videoCtrl.removeListener(_onVideoProgress);
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent — MagicalSkyBackground shows through behind the video.
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Character / video (250×250) ───────────────────────────
                // ShaderMask fades the edges to transparent via a radial
                // gradient (BlendMode.dstIn), so the character appears to
                // emerge from the sky background instead of sitting on top.
                ShaderMask(
                  shaderCallback: (rect) => const RadialGradient(
                    center: Alignment.center,
                    radius: 0.78,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.62, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: Center(
                      child: _videoReady
                          // AspectRatio keeps the video's native ratio —
                          // no stretching, letterboxed inside the 250×250 area.
                          ? AspectRatio(
                              aspectRatio: _videoCtrl.value.aspectRatio,
                              child: VideoPlayer(_videoCtrl),
                            )
                          : Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Rainbow title ─────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFB347),
                      Color(0xFFFFD700),
                      Color(0xFF34D399),
                      Color(0xFF60A5FA),
                      Color(0xFFC084FC),
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
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Tagline
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
