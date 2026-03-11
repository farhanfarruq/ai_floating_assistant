// lib/core/constants/app_constants.dart
class AppConstants {
  // Nama aplikasi
  static const String appName = 'AI Floating Assistant';

  // Ukuran bubble
  static const double bubbleSize = 65.0;

  // Ukuran panel AI
  static const double panelWidth = 320.0;
  static const double panelHeight = 500.0;

  // Timeout request AI (detik)
  static const int aiTimeoutSeconds = 30;

  // Jumlah maksimum riwayat chat yang disimpan
  static const int maxChatHistory = 100;

  // Kunci Hive boxes
  static const String chatBoxName = 'chat_history';
  static const String settingsBoxName = 'settings';
}
