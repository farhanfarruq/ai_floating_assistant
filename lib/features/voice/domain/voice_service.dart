// lib/features/voice/domain/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/utils/logger.dart';

/// Service untuk konversi suara ke teks
class VoiceService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  static String _lastWords = '';

  /// Inisialisasi speech recognition
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => AppLogger.error('Speech Error', error),
        onStatus: (status) => AppLogger.info('Speech Status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      AppLogger.error('Speech Init Error', e);
      return false;
    }
  }

  /// Mulai mendengarkan suara
  static Future<void> startListening() async {
    if (!await initialize()) return;

    _lastWords = '';

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        AppLogger.info('Recognized: $_lastWords');
      },
      localeId: 'id_ID', // Bahasa Indonesia
      listenMode: ListenMode.dictation, // Mode dikte (tidak berhenti otomatis)
      listenOptions: SpeechListenOptions(cancelOnError: false),
      partialResults: true, // Update realtime saat berbicara
    );
  }

  /// Stop mendengarkan dan kembalikan teks
  static Future<String?> stopListening() async {
    await _speech.stop();
    return _lastWords.isNotEmpty ? _lastWords : null;
  }

  /// Cek apakah sedang mendengarkan
  static bool get isListening => _speech.isListening;

  /// Cek apakah tersedia
  static bool get isAvailable => _isInitialized;
}
