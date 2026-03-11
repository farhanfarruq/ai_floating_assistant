// lib/core/utils/image_utils.dart
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  
  /// Kompresi gambar di background thread (Isolate)
  /// Agar tidak memblokir UI thread
  static Future<Uint8List> compressInBackground(Uint8List bytes) async {
    // Gunakan Isolate untuk operasi berat
    return await Isolate.run(() => _compress(bytes));
  }
  
  static Uint8List _compress(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    
    // Resize ke max 800px width untuk OCR
    final resized = image.width > 800 
        ? img.copyResize(image, width: 800) 
        : image;
    
    // JPEG 80% quality - optimal untuk OCR
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }
  
  /// Konversi ke grayscale untuk meningkatkan akurasi OCR
  static Uint8List toGrayscale(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    final gray = img.grayscale(image);
    return Uint8List.fromList(img.encodePng(gray));
  }
}
