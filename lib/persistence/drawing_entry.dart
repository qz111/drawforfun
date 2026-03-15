/// Identifies whether a drawing is a built-in animal template or a user upload.
enum DrawingType { template, upload }

/// Represents one saved drawing session.
///
/// Template entries have [overlayAssetPath] (SVG asset).
/// Upload entries have [overlayFilePath] (local PNG file).
/// Exactly one of the two is non-null.
class DrawingEntry {
  /// Folder name: animal ID (e.g. 'cat') or timestamp (e.g. 'upload_20260315_120000').
  final String id;

  final DrawingType type;

  /// SVG asset path — templates only. e.g. 'assets/line_art/cat.svg'.
  final String? overlayAssetPath;

  /// Absolute path to the converted line art PNG — uploads only.
  final String? overlayFilePath;

  /// Absolute path to this entry's storage folder.
  final String directoryPath;

  const DrawingEntry({
    required this.id,
    required this.type,
    this.overlayAssetPath,
    this.overlayFilePath,
    required this.directoryPath,
  });

  /// Path to the serialized stroke history JSON file.
  String get strokesPath => '$directoryPath/strokes.json';

  /// Path to the latest colored PNG thumbnail.
  String get thumbnailPath => '$directoryPath/thumbnail.png';

  /// Path to the overlay PNG file (uploads only).
  String get overlayPngPath => '$directoryPath/overlay.png';
}
