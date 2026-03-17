import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

/// Dedicated service for E-ink display.
class EinkService {
  /// Converts asset image to 8-bit grayscale base64 for /api/display/update
  static Future<String> convertAssetToBase64(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    var image = img.decodeImage(bytes)!;
    image = img.copyResize(image, width: 400, height: 300);
    image = img.grayscale(image);   // 8-bit grayscale

    // Convert to raw grayscale bytes (0-255)
    final buffer = Uint8List(image.width * image.height);
    int index = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        buffer[index++] = pixel.r.toInt();   // grayscale value
      }
    }

    return base64Encode(buffer);
  }
}