// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/storage_service.dart';
import 'features/overlay/presentation/overlay_entry.dart';
import 'features/overlay/presentation/home_screen.dart';
import 'features/overlay/presentation/splash_screen.dart';

/// Entry point khusus untuk overlay window (isolate terpisah dari main app).
/// PENTING: Jangan inisialisasi Hive di sini karena main app sudah buka box yang sama
/// → akan conflict dan crash, menyebabkan bubble tidak pernah muncul.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  // Overlay berjalan di Flutter engine terpisah — TIDAK membuka Hive.
  // Config (API key dll) diterima via FlutterOverlayWindow.overlayListener stream.
  runApp(const OverlayEntryWidget());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa status bar & navigation bar transparan agar UI full-immersive
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Kunci orientasi ke portrait agar layout konsisten
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: AiFloatingAssistantApp(),
    ),
  );
}

class AiFloatingAssistantApp extends StatefulWidget {
  const AiFloatingAssistantApp({super.key});

  @override
  State<AiFloatingAssistantApp> createState() => _AiFloatingAssistantAppState();
}

class _AiFloatingAssistantAppState extends State<AiFloatingAssistantApp> {
  /// Future yang menjalankan seluruh inisialisasi.
  /// Disimpan sebagai field agar tidak dijalankan ulang saat rebuild.
  late final Future<void> _initFuture = _initialize();

  Future<void> _initialize() async {
    // Inisialisasi Hive & storage — ini yang bikin jeda kalau tidak ada splash
    await Hive.initFlutter();
    await StorageService.init();

    // Delay minimal agar animasi splash sempat terlihat.
    // 500ms sudah cukup — Hive init sendiri ~100-200ms.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Floating Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Builder untuk memastikan SystemChrome diterapkan di setiap halaman
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppTheme.backgroundColor,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          // Selama inisialisasi → tampilkan splash screen animasi
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }

          // Inisialisasi selesai → transisi smooth ke HomeScreen
          return const _HomeTransition();
        },
      ),
    );
  }
}

/// Widget wrapper yang memberi animasi fade-in saat HomeScreen pertama kali muncul
/// setelah splash screen selesai.
class _HomeTransition extends StatefulWidget {
  const _HomeTransition();

  @override
  State<_HomeTransition> createState() => _HomeTransitionState();
}

class _HomeTransitionState extends State<_HomeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    // Mulai fade-in segera setelah widget mount
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const HomeScreen(),
    );
  }
}
