// lib/core/config/overlay_config.dart
// Konfigurasi in-memory untuk overlay engine (tidak pakai Hive)
// Overlay menerima ini via FlutterOverlayWindow.overlayListener stream

class OverlayConfig {
  static String _geminiApiKey = '';
  static String _openAiApiKey = '';
  static String _provider = 'gemini';

  static String get geminiApiKey => _geminiApiKey;
  static String get openAiApiKey => _openAiApiKey;
  static String get aiProvider => _provider;

  /// Active API key berdasarkan provider yang dipilih
  static String get activeApiKey =>
      _provider == 'gemini' ? _geminiApiKey : _openAiApiKey;

  static bool get hasApiKey => activeApiKey.isNotEmpty;

  /// Terima data dari main app via overlay channel
  static void updateFromData(dynamic data) {
    if (data is Map) {
      _geminiApiKey = (data['gemini_key'] as String?) ?? _geminiApiKey;
      _openAiApiKey = (data['openai_key'] as String?) ?? _openAiApiKey;
      _provider = (data['provider'] as String?) ?? _provider;
    }
  }
}
