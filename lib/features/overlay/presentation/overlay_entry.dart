// lib/features/overlay/presentation/overlay_entry.dart
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/overlay_config.dart';
import 'overlay_widget.dart';

/// Widget root untuk overlay window yang berjalan di Flutter engine terpisah.
///
/// Engine ini BERBEDA dari main app — Hive & StorageService TIDAK diinisialisasi
/// di sini. Konfigurasi (API key, provider) diterima dari main app via
/// [FlutterOverlayWindow.overlayListener] stream.
///
/// PENTING: Jaga widget ini se-simple mungkin. Hindari:
///   - Inisialisasi plugin berat (Hive, SQLite, dll)
///   - Widget tree yang terlalu dalam sebelum bubble terbuild
///   - SystemChrome calls di dalam build() — dapat crash di overlay context
class OverlayEntryWidget extends StatefulWidget {
  const OverlayEntryWidget({super.key});

  @override
  State<OverlayEntryWidget> createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<OverlayEntryWidget> {
  @override
  void initState() {
    super.initState();
    _listenToMainApp();
  }

  /// Dengarkan data yang dikirim dari main app via overlay data channel.
  /// Data berupa Map: { 'type': 'config', 'gemini_key': ..., 'openai_key': ..., 'provider': ... }
  void _listenToMainApp() {
    FlutterOverlayWindow.overlayListener.listen(
      (dynamic data) {
        if (data == null) return;
        OverlayConfig.updateFromData(data);
        // setState tidak diperlukan — OverlayConfig adalah in-memory static,
        // AiService akan membaca nilainya saat request berikutnya dibuat.
      },
      onError: (Object error) {
        // Jangan crash — overlay tetap berjalan meski config tidak diterima
        debugPrint('[OverlayEntry] overlayListener error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Background transparan di level MaterialApp agar area di luar bubble
      // tidak menampilkan warna hitam solid.
      color: Colors.transparent,

      home: const Scaffold(
        // WAJIB: Scaffold background harus transparan agar hanya bubble
        // yang terlihat, bukan kotak hitam penuh.
        backgroundColor: Colors.transparent,
        body: FloatingBubbleWidget(),
      ),
    );
  }
}
