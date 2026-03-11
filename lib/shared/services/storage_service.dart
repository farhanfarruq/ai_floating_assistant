// lib/shared/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Service untuk penyimpanan lokal menggunakan Hive
class StorageService {
  static late Box _settingsBox;

  /// Inisialisasi semua Hive boxes
  static Future<void> init() async {
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  }

  // ============ GEMINI API KEY ============

  static String get geminiApiKey =>
      _settingsBox.get('gemini_api_key', defaultValue: '') as String;

  static Future<void> setGeminiApiKey(String key) async {
    await _settingsBox.put('gemini_api_key', key);
  }

  // ============ OPENAI API KEY ============

  static String get openAiApiKey =>
      _settingsBox.get('openai_api_key', defaultValue: '') as String;

  static Future<void> setOpenAiApiKey(String key) async {
    await _settingsBox.put('openai_api_key', key);
  }

  // ============ AI PROVIDER ============

  static String get aiProvider =>
      _settingsBox.get('ai_provider', defaultValue: 'gemini') as String;

  static Future<void> setAiProvider(String provider) async {
    await _settingsBox.put('ai_provider', provider);
  }

  /// Helper: ambil API key sesuai provider aktif
  static String get activeApiKey {
    return aiProvider == 'gemini' ? geminiApiKey : openAiApiKey;
  }

  // ============ SETTINGS UMUM ============

  static bool get isDarkMode =>
      _settingsBox.get('dark_mode', defaultValue: true) as bool;

  static Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('dark_mode', value);
  }

  static String get language =>
      _settingsBox.get('language', defaultValue: 'id') as String;

  static Future<void> setLanguage(String lang) async {
    await _settingsBox.put('language', lang);
  }

  /// Hapus semua data tersimpan
  static Future<void> clearAll() async {
    await _settingsBox.clear();
  }
}
