import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/clay_ink_well.dart';
import 'template_lib_screen.dart';
import 'my_upload_lib_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Gradient logo title ──────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.accentPrimary,    // indigo-violet
                      AppColors.accentSecondary,  // candy-pink
                      AppColors.accentMint,       // mint
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    '🎨 Draw For Fun',
                    style: GoogleFonts.fredoka(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // masked by ShaderMask
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What do you want to color today?',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 52),

                // ── Menu cards ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MenuCard(
                        emoji: '🐾',
                        label: 'Templates',
                        subtitle: 'Animals & your photos',
                        accentColor: AppColors.accentPrimary,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TemplateLibScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _MenuCard(
                        emoji: '📷',
                        label: 'My Uploads',
                        subtitle: 'Line art from photos',
                        accentColor: AppColors.success,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyUploadLibScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 2.5,
          ),
          boxShadow: AppShadows.clay(accentColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
