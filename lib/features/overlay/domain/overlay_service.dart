// lib/features/overlay/domain/overlay_service.dart
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/services/storage_service.dart';

/// Service utama untuk mengelola siklus hidup floating overlay window.
///
/// Semua interaksi dengan [FlutterOverlayWindow] terpusat di sini
/// agar logging dan error handling konsisten.
class OverlayService {
  // ════════════════════════════════════════════════════════════════
  //  PERMISSION
  // ════════════════════════════════════════════════════════════════

  /// Cek apakah izin SYSTEM_ALERT_WINDOW sudah diberikan pengguna.
  static Future<bool> checkPermission() async {
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      AppLogger.info('Permission granted: $granted');
      return granted;
    } catch (e) {
      AppLogger.error('checkPermission error', e);
      return false;
    }
  }

  /// Buka halaman pengaturan Android agar pengguna bisa memberi izin overlay.
  static Future<void> requestPermission() async {
    try {
      AppLogger.info('Requesting overlay permission...');
      await FlutterOverlayWindow.requestPermission();
    } catch (e) {
      AppLogger.error('requestPermission error', e);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  SHOW BUBBLE
  // ════════════════════════════════════════════════════════════════

  /// Tampilkan floating bubble.
  ///
  /// Alur:
  ///   1. Verifikasi izin sudah granted.
  ///   2. Jika overlay sudah aktif → kirim ulang config, return true.
  ///   3. Panggil showOverlay() lalu kirim config ke overlay engine.
  static Future<bool> showBubble() async {
    try {
      // 1. Cek izin
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        AppLogger.warning('showBubble: permission not granted');
        await requestPermission();
        return false;
      }

      // 2. Jika overlay sudah aktif — cukup kirim ulang config
      final alreadyActive = await isActive();
      if (alreadyActive) {
        AppLogger.info('showBubble: overlay already active, refreshing config');
        await _sendConfig();
        return true;
      }

      // 3. Tampilkan overlay
      AppLogger.info('showBubble: calling showOverlay...');
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: AppConstants.appName,
        overlayContent: 'AI Floating Assistant aktif',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: AppConstants.bubbleSize.toInt(),
        height: AppConstants.bubbleSize.toInt(),
        startPosition: const OverlayPosition(0, 200),
      );

      // Tunggu overlay engine siap sebelum mengirim config.
      // 1500ms agar engine Dart kedua selesai init dan mendaftarkan listener.
      await Future.delayed(const Duration(milliseconds: 1500));
      await _sendConfig();

      AppLogger.info('showBubble: success');
      return true;
    } catch (e) {
      AppLogger.error('showBubble error', e);
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  HIDE BUBBLE
  // ════════════════════════════════════════════════════════════════

  /// Matikan / sembunyikan floating bubble.
  ///
  /// Alur:
  ///   1. Panggil closeOverlay().
  ///   2. Jika tidak throw → return true.
  ///   3. Jika throw → retry sekali, kemudian return false jika masih gagal.
  static Future<bool> hideBubble() async {
    try {
      AppLogger.info('hideBubble: calling closeOverlay...');
      await FlutterOverlayWindow.closeOverlay();
      AppLogger.info('hideBubble: success');
      return true;
    } catch (e) {
      AppLogger.error('hideBubble first attempt error', e);

      // Retry sekali setelah jeda singkat
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await FlutterOverlayWindow.closeOverlay();
        AppLogger.info('hideBubble: success on retry');
        return true;
      } catch (e2) {
        AppLogger.error('hideBubble retry error', e2);
        return false;
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  IS ACTIVE
  // ════════════════════════════════════════════════════════════════

  /// Cek apakah overlay sedang aktif saat ini.
  static Future<bool> isActive() async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      AppLogger.error('isActive error', e);
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════

  /// Kirim konfigurasi (API key & provider) ke overlay engine via data channel.
  ///
  /// Overlay engine menerima data ini di [OverlayConfig.updateFromData()]
  /// yang dipanggil dari [FlutterOverlayWindow.overlayListener].
  static Future<void> _sendConfig() async {
    try {
      final data = {
        'type': 'config',
        'gemini_key': StorageService.geminiApiKey,
        'openai_key': StorageService.openAiApiKey,
        'provider': StorageService.aiProvider,
      };
      await FlutterOverlayWindow.shareData(data);
      AppLogger.info(
          'Config sent to overlay engine: provider=${data['provider']}');
    } catch (e) {
      AppLogger.error('_sendConfig error', e);
      // Tidak re-throw — config bisa dikirim ulang nanti lewat
      // Settings → Save yang memanggil showBubble() lagi.
    }
  }
}
