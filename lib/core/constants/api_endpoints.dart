// lib/core/constants/api_endpoints.dart

/// Kumpulan URL endpoint untuk layanan AI
class ApiEndpoints {
  // ============ OpenAI ============
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String chatCompletions = '/chat/completions';

  // ============ Google Gemini ============
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiGenerate =
      '/models/gemini-1.5-flash:generateContent';
  static const String geminiVision = '/models/gemini-1.5-flash:generateContent';
}
