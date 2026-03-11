// lib/features/ocr/domain/ocr_service.dart
import 'dart:io';
import 'dart:ui' show Rect;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/utils/logger.dart';

/// Service untuk ekstraksi teks dari gambar (OCR)
/// Menggunakan Google ML Kit yang bekerja OFFLINE
class OcrService {
  // TextRecognizer bisa mengenali teks Latin, Cina, Devanagari, dll.
  static final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin, // Untuk teks Latin/Indonesia/Inggris
  );

  /// Ekstrak semua teks dari gambar
  static Future<String> extractText(File imageFile) async {
    try {
      // Buat InputImage dari file
      final inputImage = InputImage.fromFile(imageFile);

      // Proses OCR
      final RecognizedText recognizedText =
          await _recognizer.processImage(inputImage);

      // Gabungkan semua teks yang ditemukan
      final StringBuffer buffer = StringBuffer();

      for (final TextBlock block in recognizedText.blocks) {
        // Setiap block adalah paragraf/kelompok teks
        for (final TextLine line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Baris kosong antar blok
      }

      final result = buffer.toString().trim();
      AppLogger.info('OCR berhasil: ${result.length} karakter ditemukan');

      return result.isEmpty ? 'Tidak ada teks yang ditemukan di layar' : result;
    } catch (e) {
      AppLogger.error('OCR Error', e);
      return 'Gagal membaca teks: $e';
    }
  }

  /// Ekstrak teks dengan informasi posisi
  static Future<List<OcrBlock>> extractTextWithPositions(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _recognizer.processImage(inputImage);

      return recognizedText.blocks
          .map((block) => OcrBlock(
                text: block.text,
                boundingBox: block.boundingBox,
                confidence: block.lines.isNotEmpty
                    ? block.lines.first.elements.first.confidence ?? 0.0
                    : 0.0,
              ))
          .toList();
    } catch (e) {
      AppLogger.error('OCR Position Error', e);
      return [];
    }
  }

  /// Jangan lupa menutup recognizer saat tidak digunakan
  static void dispose() {
    _recognizer.close();
  }
}

/// Model untuk blok teks dengan posisi
class OcrBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });
}
