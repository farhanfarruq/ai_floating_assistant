// lib/shared/services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';
import '../../core/config/overlay_config.dart';
import 'storage_service.dart';

/// Model untuk pesan chat
class ChatMessage {
  final String role; // 'user' atau 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, String> toJson() => {
        'role': role,
        'content': content,
      };
}

/// Service utama untuk komunikasi dengan AI (OpenAI / Gemini)
class AiService {
  late final Dio _dio;

  /// Model OpenAI
  static const String _openAiModel = 'gpt-4o-mini';
  static const String _openAiVisionModel = 'gpt-4o';

  /// OpenAI API URL
  static const String _openAiBaseUrl = 'https://api.openai.com/v1';
  static const String _openAiChatPath = '/chat/completions';

  /// Gemini API URL
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _geminiModel = 'gemini-1.5-flash';

  AiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // Ambil API key — coba StorageService dulu (main app), fallback ke OverlayConfig (overlay engine)
  String get _apiKey {
    try {
      final key = StorageService.activeApiKey;
      return key;
    } catch (_) {
      // StorageService belum diinit (overlay context) — pakai OverlayConfig
      return OverlayConfig.activeApiKey;
    }
  }

  String get _provider {
    try {
      return StorageService.aiProvider;
    } catch (_) {
      return OverlayConfig.aiProvider;
    }
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  // ===================================================================
  //  PUBLIC API
  // ===================================================================

  /// Kirim pesan teks ke AI
  Future<String> sendMessage({
    required String userMessage,
    List<ChatMessage> history = const [],
    String systemPrompt = '',
  }) async {
    if (!hasApiKey) {
      return '⚠️ API key belum diset. Buka ⚙️ Settings untuk memasukkan API key kamu.';
    }

    try {
      if (_provider == 'gemini') {
        return await _geminiChat(
          userMessage: userMessage,
          history: history,
          systemPrompt: systemPrompt,
        );
      } else {
        return await _openAiChat(
          userMessage: userMessage,
          history: history,
          systemPrompt: systemPrompt,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('AI Service Error', e);
      return _handleDioError(e);
    } catch (e) {
      AppLogger.error('Unknown AI Error', e);
      return 'Maaf, terjadi kesalahan. Silakan coba lagi.';
    }
  }

  /// Analisis screenshot menggunakan AI Vision
  Future<String> analyzeScreenshot({
    required File imageFile,
    required String question,
  }) async {
    if (!hasApiKey) {
      return '⚠️ API key belum diset. Buka ⚙️ Settings untuk memasukkan API key kamu.';
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (_provider == 'gemini') {
        return await _geminiVision(base64Image, question);
      } else {
        return await _openAiVision(base64Image, question);
      }
    } on DioException catch (e) {
      AppLogger.error('Vision AI Error', e);
      return _handleDioError(e);
    } catch (e) {
      AppLogger.error('Vision Error', e);
      return 'Gagal menganalisis gambar: $e';
    }
  }

  /// Terjemahkan teks ke bahasa target
  Future<String> translateText(String text, String targetLanguage) async {
    return sendMessage(
      userMessage: 'Terjemahkan teks berikut ke $targetLanguage:\n\n$text',
      systemPrompt: 'Kamu adalah penerjemah profesional. '
          'Terjemahkan dengan akurat dan natural. Hanya tampilkan hasil terjemahan saja.',
    );
  }

  /// Ringkas teks panjang
  Future<String> summarizeText(String text) async {
    return sendMessage(
      userMessage: 'Ringkas teks berikut dalam 3-5 kalimat:\n\n$text',
      systemPrompt: 'Kamu adalah asisten yang ahli meringkas teks. '
          'Berikan ringkasan yang singkat dan padat.',
    );
  }

  // ===================================================================
  //  GEMINI IMPLEMENTATION
  // ===================================================================

  Future<String> _geminiChat({
    required String userMessage,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async {
    final url =
        '$_geminiBaseUrl/models/$_geminiModel:generateContent?key=$_apiKey';

    final contents = <Map<String, dynamic>>[];

    // Tambahkan history
    for (final msg in history) {
      contents.add({
        'role': msg.role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg.content}
        ],
      });
    }

    // Tambahkan pesan sekarang
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final systemInstruction = systemPrompt.isNotEmpty
        ? systemPrompt
        : 'Kamu adalah AI Assistant yang membantu pengguna memahami konten di layar mereka. '
            'Berikan jawaban yang singkat, jelas, dan helpful. '
            'Gunakan bahasa Indonesia kecuali diminta berbeda.';

    final response = await _dio.post(url, data: {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': 1024,
        'temperature': 0.7,
      },
    });

    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  Future<String> _geminiVision(String base64Image, String question) async {
    final url =
        '$_geminiBaseUrl/models/$_geminiModel:generateContent?key=$_apiKey';

    final prompt = question.isNotEmpty
        ? question
        : 'Jelaskan isi layar ini secara singkat dan berguna dalam bahasa Indonesia.';

    final response = await _dio.post(url, data: {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            },
            {'text': prompt},
          ]
        }
      ],
      'generationConfig': {'maxOutputTokens': 1024},
    });

    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  // ===================================================================
  //  OPENAI IMPLEMENTATION
  // ===================================================================

  Future<String> _openAiChat({
    required String userMessage,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async {
    final messages = <Map<String, String>>[];

    messages.add({
      'role': 'system',
      'content': systemPrompt.isNotEmpty
          ? systemPrompt
          : 'Kamu adalah AI Assistant yang membantu pengguna memahami konten di layar mereka. '
              'Berikan jawaban yang singkat, jelas, dan helpful. '
              'Gunakan bahasa Indonesia kecuali diminta berbeda.',
    });

    messages.addAll(history.map((m) => m.toJson()));
    messages.add({'role': 'user', 'content': userMessage});

    final response = await _dio.post(
      '$_openAiBaseUrl$_openAiChatPath',
      options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      data: {
        'model': _openAiModel,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _openAiVision(String base64Image, String question) async {
    final prompt = question.isNotEmpty
        ? question
        : 'Jelaskan apa yang kamu lihat di layar ini. Berikan analisis singkat dan berguna.';

    final response = await _dio.post(
      '$_openAiBaseUrl$_openAiChatPath',
      options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      data: {
        'model': _openAiVisionModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'high',
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'max_tokens': 1024,
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  // ===================================================================
  //  ERROR HANDLING
  // ===================================================================

  String _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Request tidak valid. Periksa API key dan coba lagi.';
      case 401:
        return '❌ API key tidak valid atau sudah kadaluarsa. Periksa di ⚙️ Settings.';
      case 403:
        return '⛔ Akses ditolak. Pastikan API key memiliki akses yang benar.';
      case 429:
        return '⏳ Batas penggunaan API tercapai. Coba lagi sebentar.';
      case 500:
        return '🔧 Server AI sedang bermasalah. Coba lagi nanti.';
      default:
        if (e.type == DioExceptionType.connectionTimeout) {
          return '📡 Koneksi timeout. Periksa koneksi internet kamu.';
        }
        if (e.type == DioExceptionType.receiveTimeout) {
          return '⏱️ Respons AI terlalu lama. Coba lagi.';
        }
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
