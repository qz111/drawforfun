import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../persistence/drawing_entry.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Polaroid-style drawing card with washi tape, plant decoration,
/// and alternating tilt. Drop-in replacement for DrawingCardWidget
/// (identical public API).
class PolaroidCardWidget extends StatelessWidget {
  final DrawingEntry entry;
  final String label;
  final String? emoji;
  final bool hasThumbnail;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  // Card index drives tilt direction and decoration colour cycling
  final int index;

  // ignore: prefer_const_constructors_in_immutables
  PolaroidCardWidget({
    super.key,
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
    required this.onTap,
    this.onDelete,
    this.onLongPress,
    this.index = 0,
  });

  // ── Decoration cycles (4 variants, index % 4) ──────────────────────────

  static const _imageGradients = [
    [Color(0xFFAAFFD4), Color(0xFF67E8F9)], // mint → cyan
    [Color(0xFFC8F0FF), Color(0xFFA5F3FB)], // ice-blue → sky
    [Color(0xFFFDBA74), Color(0xFFFCA5A5)], // peach → coral
    [Color(0xFFFFD6F5), Color(0xFFFBCFE8)], // candy-pink → rose
  ];

  static const _plants = ['🌿', '🌸', '🌻', '🌺'];

  static const _tapeColors = [
    [Color(0xFFA78BFA), Color(0xFFC4B5FD)], // violet
    [Color(0xFFFDE68A), Color(0xFFFEF08A)], // yellow
    [Color(0xFF6EE7B7), Color(0xFFA7F3D0)], // mint
    [Color(0xFFFBCFE8), Color(0xFFFCE7F3)], // pink
  ];

  @override
  Widget build(BuildContext context) {
    final vi = index % 4;
    final angle = index % 2 == 0 ? -0.04 : 0.05;

    // Outer Stack: delete button lives here (unrotated) so its hit area
    // matches the visible position after the card is tilted.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Rotated polaroid card ──────────────────────────────────────
        Transform.rotate(
          angle: angle,
          child: ClayInkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // White card body
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.14),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image area
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 140,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Gradient background
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _imageGradients[vi],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              // Thumbnail / SVG / placeholder
                              _buildThumbnail(),
                              // Plant decoration (bottom-left, clipped)
                              Positioned(
                                bottom: 4,
                                left: 6,
                                child: Text(
                                  _plants[vi],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              // Sparkle (top-right)
                              const Positioned(
                                top: 6,
                                right: 8,
                                child: Text('✨', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Label strip
                      Container(
                        height: 44,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _StatusPill(hasThumbnail: hasThumbnail),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Washi tape — overhangs top of card by 8 px
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.02,
                      child: Opacity(
                        opacity: 0.65,
                        child: Container(
                          width: 44,
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _tapeColors[vi],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Delete button (outside rotation — correct hit area) ───────
        if (onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  boxShadow: AppShadows.soft(AppColors.danger),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    if (hasThumbnail) {
      return Image.file(
        File(entry.thumbnailPath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (entry.type == DrawingType.template && entry.overlayAssetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Opacity(
          opacity: 0.35,
          child: SvgPicture.asset(
            entry.overlayAssetPath!,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => _placeholder(),
          ),
        ),
      );
    }
    if (entry.overlayFilePath != null) {
      return Image.file(
        File(entry.overlayFilePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        emoji ?? '📷',
        style: const TextStyle(fontSize: 32),
      ),
    );
  }
}

// ── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool hasThumbnail;
  const _StatusPill({required this.hasThumbnail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: hasThumbnail
            ? AppColors.accentPrimary.withValues(alpha: 0.15)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        hasThumbnail ? '● colored' : 'not started',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: hasThumbnail ? AppColors.accentPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
