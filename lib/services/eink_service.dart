import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

/// Dedicated service for E-ink display.
class EinkService {
  /// Converts asset image to grayscale PNG bytes (base64) for /api/display/update.
  static Future<String> convertAssetToBase64(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image: $assetPath');
    }

    var image = img.copyResize(decoded, width: 400, height: 300);
    image = img.grayscale(image);

    // IMPORTANT: send encoded image bytes, not raw per-pixel buffer.
    final pngBytes = img.encodePng(image, level: 0);
    return base64Encode(pngBytes);
  }
}