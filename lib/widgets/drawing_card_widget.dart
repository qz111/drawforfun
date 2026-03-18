import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../persistence/drawing_entry.dart';

/// A tappable card showing a drawing's thumbnail (or placeholder if not started).
///
/// [hasThumbnail] must be pre-computed by the caller (e.g. `File(entry.thumbnailPath).existsSync()`)
/// to avoid synchronous file I/O inside `build()`.
class DrawingCardWidget extends StatelessWidget {
  final DrawingEntry entry;

  /// Display name shown below the thumbnail.
  final String label;

  /// Emoji shown as fallback placeholder — templates only.
  final String? emoji;

  /// Whether a saved thumbnail PNG exists for this entry.
  final bool hasThumbnail;

  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  // ignore: prefer_const_constructors_in_immutables
  DrawingCardWidget({
    super.key,
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
    required this.onTap,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: _buildThumbnail(),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasThumbnail ? '● colored' : 'not started',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasThumbnail
                              ? Colors.deepPurple.shade300
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    // 1. Colored thumbnail (highest priority)
    if (hasThumbnail) {
      return Image.file(
        File(entry.thumbnailPath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // 2. Template — show blank SVG line art at reduced opacity
    if (entry.type == DrawingType.template &&
        entry.overlayAssetPath != null) {
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
    // 3. Upload — show the raw line art PNG preview.
    // overlayFilePath is always non-null for upload entries and the file is
    // guaranteed to exist (written by createUploadEntry). Use errorBuilder
    // as a safety fallback instead of a synchronous existsSync() check.
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
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Text(
          emoji ?? '📷',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
