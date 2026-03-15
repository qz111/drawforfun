import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

// image_gallery_saver is only available on iOS/Android
// Import conditionally at runtime via Platform check
import 'package:image_gallery_saver/image_gallery_saver.dart'
    if (dart.library.html) 'package:drawforfun/save/stub_gallery_saver.dart';

class SaveManager {
  SaveManager._();

  /// Generates a timestamped filename like `coloring_20260314_143022.png`.
  static String generateFilename() {
    final now = DateTime.now();
    final date =
        '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final time =
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'coloring_${date}_$time.png';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Captures [repaintKey]'s render object as PNG bytes.
  static Future<Uint8List?> captureCanvas(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Saves [bytes] as a PNG to the app's documents directory.
  /// Returns the saved file path on success, null on failure.
  static Future<String?> saveToAppDocuments(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${generateFilename()}');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Saves [bytes] to the device photo library.
  /// On Windows (dev environment) this is a no-op that returns false.
  static Future<bool> saveToGallery(Uint8List bytes) async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 95,
        name: generateFilename(),
      );
      return result['isSuccess'] == true;
    } catch (e) {
      return false;
    }
  }
}
