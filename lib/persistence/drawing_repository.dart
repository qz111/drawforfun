import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import '../templates/animal_template.dart';
import 'drawing_entry.dart';

/// File-based persistence for drawing sessions.
///
/// All data lives under `<app_documents>/drawforfun/drawings/<id>/`.
/// Each entry folder contains:
///   strokes.json   — serialized stroke history
///   thumbnail.png  — latest colored snapshot
///   overlay.png    — converted line art PNG (uploads only)
///
/// For testing, call [setTestDirectory] with a temp dir before any operations,
/// and pass null to restore the real path_provider behaviour.
class DrawingRepository {
  DrawingRepository._();

  static Directory? _testOverrideDir;

  /// Injects a temp directory for unit tests, bypassing path_provider.
  @visibleForTesting
  static void setTestDirectory(Directory? dir) => _testOverrideDir = dir;

  // ── Internal path helpers ──────────────────────────────────────────

  static Future<Directory> _drawingsDir() async {
    // In tests, return the injected directory as-is (no 'drawings/' subfolder).
    if (_testOverrideDir != null) return _testOverrideDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final drawings = Directory('${appDir.path}/drawforfun/drawings');
    if (!drawings.existsSync()) drawings.createSync(recursive: true);
    return drawings;
  }

  static Future<Directory> _entryDir(String id) async {
    final base = await _drawingsDir();
    final dir = Directory('${base.path}/$id');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Extracts the last path segment from a platform-native path.
  static String _basename(String p) {
    final clean = p.replaceAll('\\', '/');
    final parts = clean.split('/');
    return parts.lastWhere((s) => s.isNotEmpty, orElse: () => '');
  }

  // ── Public API ────────────────────────────────────────────────────

  /// Builds a [DrawingEntry] for a built-in [AnimalTemplate].
  /// Does not create the directory — it is created lazily on first save.
  static Future<DrawingEntry> templateEntry(AnimalTemplate template) async {
    final base = await _drawingsDir();
    return DrawingEntry(
      id: template.id,
      type: DrawingType.template,
      overlayAssetPath: template.assetPath,
      directoryPath: '${base.path}/${template.id}',
    );
  }

  /// Returns all upload entries, sorted newest-first.
  static Future<List<DrawingEntry>> listUploadEntries() async {
    final base = await _drawingsDir();
    if (!base.existsSync()) return [];
    final entries = base
        .listSync()
        .whereType<Directory>()
        .where((d) => _basename(d.path).startsWith('upload_'))
        .map((d) {
      final id = _basename(d.path);
      return DrawingEntry(
        id: id,
        type: DrawingType.upload,
        overlayFilePath: '${d.path}/overlay.png',
        directoryPath: d.path,
      );
    }).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // newest first (lexicographic = chronological)
    return entries;
  }

  /// Saves the stroke JSON list to `<entry>/strokes.json`.
  /// Creates the entry directory if it does not exist.
  static Future<void> saveStrokes(
    DrawingEntry entry,
    List<Map<String, dynamic>> json,
  ) async {
    await _entryDir(entry.id);
    await File(entry.strokesPath).writeAsString(jsonEncode(json));
  }

  /// Loads stroke JSON from `<entry>/strokes.json`.
  /// Returns an empty list if the file is absent or contains invalid JSON.
  static Future<List<Map<String, dynamic>>> loadStrokes(
      DrawingEntry entry) async {
    final file = File(entry.strokesPath);
    if (!file.existsSync()) return [];
    try {
      final raw = await file.readAsString();
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      assert(() {
        // ignore: avoid_print
        print('DrawingRepository: corrupt strokes.json for ${entry.id}');
        return true;
      }());
      return [];
    }
  }

  /// Writes [bytes] to `<entry>/thumbnail.png`.
  /// Creates the entry directory if it does not exist.
  static Future<void> saveThumbnail(
      DrawingEntry entry, Uint8List bytes) async {
    await _entryDir(entry.id);
    await File(entry.thumbnailPath).writeAsBytes(bytes);
  }

  /// Creates a new upload entry:
  /// 1. Generates a timestamp-based ID.
  /// 2. Creates the entry directory.
  /// 3. Writes [overlayPng] to `overlay.png`.
  /// 4. Returns the [DrawingEntry].
  static Future<DrawingEntry> createUploadEntry(Uint8List overlayPng) async {
    final now = DateTime.now();
    final id =
        'upload_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final dir = await _entryDir(id);
    final overlayPath = '${dir.path}/overlay.png';
    await File(overlayPath).writeAsBytes(overlayPng);
    return DrawingEntry(
      id: id,
      type: DrawingType.upload,
      overlayFilePath: overlayPath,
      directoryPath: dir.path,
    );
  }

  /// Creates a new raw-import entry:
  /// 1. Generates a timestamp-based ID.
  /// 2. Creates the entry directory.
  /// 3. Writes [bytes] to `overlay.png` without any processing.
  /// 4. Returns the [DrawingEntry].
  static Future<DrawingEntry> createRawImportEntry(Uint8List bytes) async {
    final now = DateTime.now();
    final id =
        'rawimport_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final dir = await _entryDir(id);
    final overlayPath = '${dir.path}/overlay.png';
    await File(overlayPath).writeAsBytes(bytes);
    return DrawingEntry(
      id: id,
      type: DrawingType.rawImport,
      overlayFilePath: overlayPath,
      directoryPath: dir.path,
    );
  }

  /// Returns all raw-import entries, sorted newest-first.
  static Future<List<DrawingEntry>> listRawImportEntries() async {
    final base = await _drawingsDir();
    if (!base.existsSync()) return [];
    final entries = base
        .listSync()
        .whereType<Directory>()
        .where((d) => _basename(d.path).startsWith('rawimport_'))
        .map((d) {
      final id = _basename(d.path);
      return DrawingEntry(
        id: id,
        type: DrawingType.rawImport,
        overlayFilePath: '${d.path}/overlay.png',
        directoryPath: d.path,
      );
    }).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return entries;
  }

  /// Permanently deletes a user-owned entry (upload or rawImport) and all its files.
  /// Throws [StateError] if called on a built-in [DrawingType.template] entry.
  static Future<void> deleteEntry(DrawingEntry entry) async {
    if (entry.type == DrawingType.template) {
      throw StateError('Cannot delete a built-in template entry: ${entry.id}');
    }
    final dir = Directory(entry.directoryPath);
    if (!dir.existsSync()) return;
    try {
      await dir.delete(recursive: true);
    } on PathAccessException {
      if (!Platform.isWindows) rethrow;
      // Fallback for Windows: OneDrive-synced paths can hold transient locks
      // that block Directory.delete. cmd rmdir /s /q bypasses these locks.
      // Normalize to backslashes: forward slashes in the path are treated
      // as switch characters by cmd's rmdir and cause "Invalid switch" errors.
      final winPath = entry.directoryPath.replaceAll('/', '\\');
      final result = await Process.run(
        'cmd', ['/c', 'rmdir', '/s', '/q', winPath],
      );
      if (result.exitCode != 0 && dir.existsSync()) {
        throw PathAccessException(
          entry.directoryPath,
          OSError('rmdir failed: ${result.stderr}', result.exitCode),
          'delete',
        );
      }
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
