// lib/features/screen_context/domain/screen_context_service.dart
import 'dart:io';
import '../../../features/screenshot/domain/screenshot_service.dart';
import '../../../features/ocr/domain/ocr_service.dart';
import '../../../shared/services/ai_service.dart';
import '../../../core/utils/logger.dart';

/// Service yang menggabungkan Screenshot + OCR untuk memberikan konteks layar ke AI
class ScreenContextService {
  final AiService _aiService = AiService();

  /// Ambil konteks lengkap dari layar saat ini (screenshot + OCR + AI analysis)
  Future<ScreenContext> captureContext({
    String? question,
  }) async {
    AppLogger.info('Capturing screen context...');

    File? imageFile;
    String ocrText = '';
    String aiAnalysis = '';

    try {
      // 1. Ambil screenshot
      imageFile = await ScreenshotService.captureScreen();

      // 2. OCR — baca teks di layar
      if (imageFile != null) {
        ocrText = await OcrService.extractText(imageFile);
        AppLogger.info('OCR result: ${ocrText.length} chars');
      }

      // 3. AI Analysis
      if (imageFile != null) {
        final q =
            question ?? 'Jelaskan apa yang ada di layar ini secara singkat.';
        aiAnalysis = await _aiService.analyzeScreenshot(
          imageFile: imageFile,
          question: q,
        );
      }
    } catch (e) {
      AppLogger.error('captureContext error', e);
    }

    return ScreenContext(
      imageFile: imageFile,
      ocrText: ocrText,
      aiAnalysis: aiAnalysis,
      capturedAt: DateTime.now(),
    );
  }

  /// Jawab pertanyaan tentang layar saat ini
  Future<String> askAboutScreen(String question) async {
    final context = await captureContext(question: question);
    if (context.aiAnalysis.isEmpty) {
      return 'Maaf, tidak bisa mengambil konteks layar saat ini.';
    }
    return context.aiAnalysis;
  }
}

/// Model data untuk konteks layar
class ScreenContext {
  final File? imageFile;
  final String ocrText;
  final String aiAnalysis;
  final DateTime capturedAt;

  const ScreenContext({
    required this.imageFile,
    required this.ocrText,
    required this.aiAnalysis,
    required this.capturedAt,
  });

  bool get hasContent => ocrText.isNotEmpty || aiAnalysis.isNotEmpty;
}
