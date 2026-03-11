// lib/features/translation/domain/translation_service.dart
import '../../../shared/services/ai_service.dart';
import '../../../core/utils/logger.dart';

/// Service untuk terjemahan teks menggunakan AI
class TranslationService {
  final AiService _aiService = AiService();

  /// Terjemahkan teks ke bahasa target
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) return '';

    final prompt = sourceLanguage != null
        ? 'Terjemahkan teks berikut dari $sourceLanguage ke $targetLanguage:\n\n$text'
        : 'Terjemahkan teks berikut ke $targetLanguage:\n\n$text';

    AppLogger.info(
        'Translating to $targetLanguage: ${text.substring(0, text.length.clamp(0, 50))}...');

    return _aiService.sendMessage(
      userMessage: prompt,
      systemPrompt:
          'Kamu adalah penerjemah profesional yang akurat dan natural. '
          'Hanya tampilkan hasil terjemahan saja, tanpa penjelasan tambahan.',
    );
  }

  /// Deteksi bahasa teks
  Future<String> detectLanguage(String text) async {
    return _aiService.sendMessage(
      userMessage:
          'Deteksi bahasa dari teks berikut dan jawab hanya dengan nama bahasanya saja: "$text"',
      systemPrompt:
          'Kamu adalah language detection expert. Jawab hanya dengan nama bahasa, contoh: "Indonesia", "English", "Chinese".',
    );
  }

  /// Terjemahkan ke Indonesia
  Future<String> toIndonesian(String text) =>
      translate(text: text, targetLanguage: 'Indonesia');

  /// Terjemahkan ke Inggris
  Future<String> toEnglish(String text) =>
      translate(text: text, targetLanguage: 'English');
}
