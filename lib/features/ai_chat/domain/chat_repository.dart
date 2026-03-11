// lib/features/ai_chat/domain/chat_repository.dart
import '../../../shared/services/ai_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import 'dart:io';

/// Repository untuk operasi chat AI — abstraksi antara UI dan AiService
class ChatRepository {
  final AiService _aiService = AiService();

  /// Kirim pesan teks dan dapatkan respons AI
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    String systemPrompt = '',
  }) async {
    AppLogger.info('Sending message to ${StorageService.aiProvider}: $message');
    return _aiService.sendMessage(
      userMessage: message,
      history: history,
      systemPrompt: systemPrompt,
    );
  }

  /// Analisis screenshot menggunakan AI Vision
  Future<String> analyzeImage({
    required File imageFile,
    required String question,
  }) async {
    AppLogger.info('Analyzing screenshot with AI vision');
    return _aiService.analyzeScreenshot(
      imageFile: imageFile,
      question: question,
    );
  }

  /// Terjemahkan teks
  Future<String> translateText(String text, String targetLang) async {
    return _aiService.translateText(text, targetLang);
  }

  /// Ringkas teks
  Future<String> summarizeText(String text) async {
    return _aiService.summarizeText(text);
  }

  /// Cek apakah API key sudah tersedia
  bool get isReady => _aiService.hasApiKey;

  /// Nama provider yang aktif
  String get providerName =>
      StorageService.aiProvider == 'gemini' ? 'Gemini' : 'ChatGPT';
}
