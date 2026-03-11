// lib/features/screenshot/domain/screenshot_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../../core/utils/logger.dart';

/// Service untuk mengambil dan memproses screenshot
class ScreenshotService {
  static final ScreenshotController _controller = ScreenshotController();
  
  /// Ambil screenshot layar saat ini
  /// Mengembalikan File gambar atau null jika gagal
  static Future<File?> captureScreen() async {
    try {
      // Capture widget sebagai bytes
      final Uint8List? bytes = await _controller.capture(
        delay: const Duration(milliseconds: 300), // Delay kecil untuk render
        pixelRatio: 2.0, // Resolusi 2x untuk kualitas lebih baik
      );
      
      if (bytes == null) {
        AppLogger.warning('Screenshot bytes null');
        return null;
      }
      
      // Kompres gambar untuk menghemat memori dan mempercepat OCR
      final compressedBytes = await _compressImage(bytes);
      
      // Simpan ke temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/screenshot_$timestamp.jpg');
      
      await file.writeAsBytes(compressedBytes);
      
      AppLogger.info('Screenshot saved: ${file.path}');
      return file;
      
    } catch (e) {
      AppLogger.error('Screenshot Error', e);
      return null;
    }
  }
  
  /// Kompres gambar untuk efisiensi
  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Decode gambar
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    
    // Resize jika terlalu besar (max 1080p)
    img.Image resized = image;
    if (image.width > 1080) {
      resized = img.copyResize(image, width: 1080);
    }
    
    // Encode ke JPEG dengan kualitas 85%
    final compressed = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(compressed);
  }
  
  /// Bungkus widget dengan ScreenshotController
  /// Panggil ini di root widget yang ingin di-capture
  static Widget wrapWithCapture({required Widget child}) {
    return Screenshot(
      controller: _controller,
      child: child,
    );
  }
  
  /// Hapus file screenshot lama untuk menghemat storage
  static Future<void> cleanupOldScreenshots() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('screenshot_'))
          .toList();
      
      // Hapus file lebih dari 10 menit
      final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.error('Cleanup Error', e);
    }
  }
}