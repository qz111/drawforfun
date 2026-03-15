/// Stub for platforms where image_gallery_saver is unavailable.
class ImageGallerySaver {
  static Future<Map<String, dynamic>> saveImage(
    dynamic bytes, {
    int quality = 80,
    String? name,
  }) async {
    return {'isSuccess': false, 'filePath': null};
  }
}
