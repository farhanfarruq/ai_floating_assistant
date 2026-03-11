// lib/features/ai_chat/data/chat_history_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/ai_service.dart';
import '../../../core/utils/logger.dart';

/// Repository untuk menyimpan & memuat riwayat chat dari Hive (lokal)
class ChatHistoryRepository {
  static Box? _box;

  static Future<Box> _getBox() async {
    _box ??= await Hive.openBox(AppConstants.chatBoxName);
    return _box!;
  }

  /// Simpan satu pesan ke history
  static Future<void> saveMessage(ChatMessage message) async {
    try {
      final box = await _getBox();
      final messages = _loadRaw(box);
      messages.add({
        'role': message.role,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
      });

      // Batasi history sesuai AppConstants
      if (messages.length > AppConstants.maxChatHistory) {
        messages.removeRange(0, messages.length - AppConstants.maxChatHistory);
      }

      await box.put('messages', messages);
    } catch (e) {
      AppLogger.error('saveMessage error', e);
    }
  }

  /// Muat semua riwayat chat
  static Future<List<ChatMessage>> loadHistory() async {
    try {
      final box = await _getBox();
      final raw = _loadRaw(box);
      return raw
          .map((m) => ChatMessage(
                role: m['role'] as String,
                content: m['content'] as String,
                timestamp: DateTime.tryParse(m['timestamp'] as String) ??
                    DateTime.now(),
              ))
          .toList();
    } catch (e) {
      AppLogger.error('loadHistory error', e);
      return [];
    }
  }

  /// Hapus semua riwayat
  static Future<void> clearHistory() async {
    try {
      final box = await _getBox();
      await box.delete('messages');
      AppLogger.info('Chat history cleared');
    } catch (e) {
      AppLogger.error('clearHistory error', e);
    }
  }

  static List<Map<String, dynamic>> _loadRaw(Box box) {
    final raw = box.get('messages');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }
}
