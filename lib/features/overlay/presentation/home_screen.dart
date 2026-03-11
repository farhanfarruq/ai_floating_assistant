// lib/features/overlay/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../domain/overlay_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isOverlayActive = false;
  bool _hasPermission = false;
  bool _isLoading = false;

  // ── Pulse icon hero ──────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  // ── Shimmer efek tombol Aktifkan ─────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double> _shimmerValue;

  // ── Fade-in seluruh konten ───────────────────────────────────────
  late AnimationController _contentFadeController;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerValue = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Content fade-in
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOverlayStatus();
      _contentFadeController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _shimmerController.dispose();
    _contentFadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 600), _syncOverlayStatus);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  LOGIKA OVERLAY
  // ════════════════════════════════════════════════════════════════

  Future<void> _syncOverlayStatus() async {
    try {
      final hasPermission = await OverlayService.checkPermission();
      final isActive = await OverlayService.isActive();
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isOverlayActive = isActive;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleOverlay() async {
    if (_isLoading) return;

    if (!_hasPermission) {
      HapticFeedback.mediumImpact();
      await OverlayService.requestPermission();
      await Future.delayed(const Duration(seconds: 1));
      await _syncOverlayStatus();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    // Timeout guard: paksa reset _isLoading setelah 10 detik
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _showSnackBar('⏱️ Operasi timeout. Silakan coba lagi.', Colors.orange);
      }
    });

    try {
      if (_isOverlayActive) {
        final success = await OverlayService.hideBubble()
            .timeout(const Duration(seconds: 8), onTimeout: () => false);

        if (mounted) {
          setState(() {
            _isOverlayActive = success ? false : _isOverlayActive;
            _isLoading = false;
          });
          if (success) {
            HapticFeedback.heavyImpact();
          } else {
            _showSnackBar(
              '⚠️ Gagal mematikan overlay. Gunakan tombol "Tutup Paksa" di bawah.',
              Colors.orange,
            );
          }
        }
      } else {
        final success = await OverlayService.showBubble()
            .timeout(const Duration(seconds: 10), onTimeout: () => false);

        if (mounted) {
          setState(() {
            _isOverlayActive = success;
            _isLoading = false;
          });
          if (success) {
            HapticFeedback.heavyImpact();
          } else {
            _showSnackBar(
              '⚠️ Gagal menampilkan overlay. Pastikan izin sudah diberikan.',
              Colors.orange,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('❌ Error: $e', Colors.red.shade700);
      }
    }
  }

  /// Tutup overlay paksa — digunakan ketika tombol utama tidak responsif
  /// atau spinner tidak berhenti. Langsung panggil closeOverlay() tanpa
  /// menunggu status dari OverlayService.
  Future<void> _forceStopOverlay() async {
    HapticFeedback.heavyImpact();
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isOverlayActive = false;
        _isLoading = false;
      });
      _showSnackBar('✅ Overlay berhasil ditutup paksa.', AppTheme.accentColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD UTAMA
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _contentFade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildToggleButton(),
                  if (!_hasPermission) ...[
                    const SizedBox(height: 12),
                    _buildPermissionBanner(),
                  ],
                  const SizedBox(height: 32),
                  _buildFeaturesGrid(),
                  const SizedBox(height: 28),
                  _buildHowToUse(),
                  // Force Stop Card — tampil saat overlay aktif ATAU loading stuck
                  if (_isOverlayActive || _isLoading) ...[
                    const SizedBox(height: 16),
                    _buildForceStopCard(),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  APP BAR
  // ════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      expandedHeight: 0,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.30),
                  AppTheme.accentColor.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assistant_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'AI Floating Assistant',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        // Indikator status ON / OFF
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isOverlayActive
                ? AppTheme.accentColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOverlayActive
                      ? AppTheme.accentColor
                      : Colors.grey.shade600,
                  boxShadow: _isOverlayActive
                      ? [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.7),
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _isOverlayActive
                      ? AppTheme.accentColor
                      : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                child: Text(_isOverlayActive ? 'ON' : 'OFF'),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: AppTheme.textSecondary,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          tooltip: 'Pengaturan',
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HERO SECTION
  // ════════════════════════════════════════════════════════════════

  Widget _buildHeroSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOverlayActive
              ? [
                  AppTheme.primaryColor.withOpacity(0.18),
                  AppTheme.accentColor.withOpacity(0.10),
                ]
              : [
                  AppTheme.primaryColor.withOpacity(0.10),
                  AppTheme.surfaceColor.withOpacity(0.60),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isOverlayActive
              ? AppTheme.accentColor.withOpacity(0.40)
              : AppTheme.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon animasi
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Transform.scale(
                scale: _isOverlayActive ? _pulseScale.value : 1.0,
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring glow luar — hanya saat aktif
                      if (_isOverlayActive)
                        Opacity(
                          opacity: ((1.0 - _pulseScale.value) * 10.0)
                              .clamp(0.0, 1.0),
                          child: Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.accentColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      // Lingkaran utama
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor
                                  .withOpacity(_isOverlayActive ? 0.65 : 0.30),
                              blurRadius: _isOverlayActive ? 28 : 12,
                              spreadRadius: _isOverlayActive ? 4 : 0,
                            ),
                            if (_isOverlayActive)
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.20),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                          ],
                        ),
                        child: const Icon(
                          Icons.assistant_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // Judul status
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              _isOverlayActive ? '✨ Overlay Aktif' : 'AI Floating Assistant',
              key: ValueKey(_isOverlayActive),
              style: TextStyle(
                color: _isOverlayActive
                    ? AppTheme.accentColor
                    : AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              _isOverlayActive
                  ? 'Bubble AI sedang mengambang di atas layarmu'
                  : 'Asisten AI yang mengambang di atas semua aplikasi',
              key: ValueKey(_isOverlayActive),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: _isOverlayActive
                  ? AppTheme.accentColor.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isOverlayActive
                    ? AppTheme.accentColor.withOpacity(0.35)
                    : Colors.grey.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOverlayActive
                        ? AppTheme.accentColor
                        : Colors.grey.shade600,
                    boxShadow: _isOverlayActive
                        ? [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.65),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOverlayActive ? 'Overlay Aktif' : 'Overlay Tidak Aktif',
                  style: TextStyle(
                    color: _isOverlayActive
                        ? AppTheme.accentColor
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOMBOL TOGGLE UTAMA
  // ════════════════════════════════════════════════════════════════

  Widget _buildToggleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Stack(
        children: [
          // Tombol dengan gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: _isOverlayActive
                          ? [Colors.red.shade700, Colors.red.shade900]
                          : [
                              AppTheme.primaryColor,
                              AppTheme.primaryDark,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isLoading ? AppTheme.surfaceColor : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: (_isOverlayActive
                                ? Colors.red
                                : AppTheme.primaryColor)
                            .withOpacity(0.42),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _toggleOverlay,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.12),
                highlightColor: Colors.white.withOpacity(0.06),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoading
                        ? _buildLoadingContent()
                        : _buildButtonContent(),
                  ),
                ),
              ),
            ),
          ),

          // Shimmer — hanya saat idle / overlay belum aktif
          if (!_isLoading && !_isOverlayActive)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(_shimmerValue.value * 240, 0),
                      child: Container(
                        width: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Row(
      key: ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Memproses...',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonContent() {
    return Row(
      key: const ValueKey('content'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isOverlayActive
              ? Icons.stop_circle_rounded
              : Icons.play_circle_filled_rounded,
          color: Colors.white,
          size: 26,
        ),
        const SizedBox(width: 10),
        Text(
          _isOverlayActive ? 'Matikan Overlay' : 'Aktifkan Overlay',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PERMISSION BANNER
  // ════════════════════════════════════════════════════════════════

  Widget _buildPermissionBanner() {
    return GestureDetector(
      onTap: () async {
        await OverlayService.requestPermission();
        await Future.delayed(const Duration(seconds: 1));
        await _syncOverlayStatus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.35)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Izin Diperlukan',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap di sini untuk memberi izin "Tampilkan di atas aplikasi lain" agar overlay bisa muncul.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.orange, size: 14),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPER: SECTION TITLE
  // ════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.25),
                AppTheme.accentColor.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  FITUR UNGGULAN
  // ════════════════════════════════════════════════════════════════

  Widget _buildFeaturesGrid() {
    final features = [
      _FeatureItem(
        icon: Icons.chat_bubble_rounded,
        title: 'AI Chat',
        desc: 'Tanya Gemini atau ChatGPT apa saja',
        color: AppTheme.primaryColor,
      ),
      _FeatureItem(
        icon: Icons.screenshot_monitor_rounded,
        title: 'Capture & Analisis',
        desc: 'Screenshot layar, analisis dengan AI',
        color: AppTheme.accentColor,
      ),
      _FeatureItem(
        icon: Icons.document_scanner_rounded,
        title: 'Baca Teks (OCR)',
        desc: 'Ekstrak teks dari layar secara offline',
        color: Colors.blueAccent,
      ),
      _FeatureItem(
        icon: Icons.mic_rounded,
        title: 'Voice Input',
        desc: 'Bicara langsung ke AI lewat suara',
        color: Colors.orange,
      ),
      _FeatureItem(
        icon: Icons.translate_rounded,
        title: 'Terjemahan',
        desc: 'Terjemahkan teks ke berbagai bahasa',
        color: Colors.green,
      ),
      _FeatureItem(
        icon: Icons.open_with_rounded,
        title: 'Draggable Bubble',
        desc: 'Bubble bebas dipindah ke mana saja',
        color: Colors.purple,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fitur Unggulan', Icons.auto_awesome_rounded),
        const SizedBox(height: 14),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // childAspectRatio lebih kecil = kartu lebih tinggi
          // sehingga konten 2-baris selalu muat di semua ukuran layar.
          childAspectRatio: 1.45,
          children: features.map(_buildFeatureCard).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: feature.color, size: 18),
          ),
          const SizedBox(height: 8),
          // Judul
          Text(
            feature.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Deskripsi — maxLines + ellipsis mencegah overflow 1.1px
          Text(
            feature.desc,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10.5,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  CARA PENGGUNAAN
  // ════════════════════════════════════════════════════════════════

  Widget _buildHowToUse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cara Penggunaan', Icons.help_outline_rounded),
        const SizedBox(height: 14),
        _buildStepCard(
          step: 1,
          title: 'Masukkan API Key',
          desc:
              'Buka ⚙️ Settings → masukkan Gemini API Key (gratis di aistudio.google.com) atau OpenAI API Key.',
          icon: Icons.key_rounded,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          step: 2,
          title: 'Izinkan Tampil di Atas App',
          desc:
              'Tap tombol "Aktifkan Overlay" → izinkan "Tampilkan di atas aplikasi lain" di pengaturan Android.',
          icon: Icons.security_rounded,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          step: 3,
          title: 'Aktifkan Bubble',
          desc:
              'Kembali ke app, tap "Aktifkan Overlay". Bubble biru bulat akan muncul mengambang di layar.',
          icon: Icons.touch_app_rounded,
          color: Colors.green,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          step: 4,
          title: 'Gunakan di Mana Saja',
          desc:
              'Bubble tetap aktif saat kamu buka aplikasi lain. Tap bubble untuk chat, tahan lama untuk menutup.',
          icon: Icons.layers_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomor langkah
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  FORCE STOP CARD
  // ════════════════════════════════════════════════════════════════

  /// Kartu darurat yang muncul saat overlay aktif atau loading macet.
  /// Menjelaskan kepada pengguna apa itu "Tutup Paksa" dan kapan menggunakannya.
  Widget _buildForceStopCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tombol Darurat Overlay',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Penjelasan — menjawab pertanyaan "apa maksudnya?"
          const Text(
            'Gunakan tombol ini HANYA jika:',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          _buildForceStopReason(
              '• Overlay tidak bisa dimatikan lewat tombol utama'),
          _buildForceStopReason(
              '• Spinner loading terus berputar lebih dari 15 detik'),
          _buildForceStopReason(
              '• Bubble masih terlihat tapi tombol "Matikan" tidak respons'),
          const SizedBox(height: 12),
          const Text(
            'Tombol ini langsung mematikan overlay dari sistem Android '
            'tanpa menunggu konfirmasi apapun.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Tombol tutup paksa
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _forceStopOverlay,
              icon: const Icon(Icons.stop_circle_rounded, size: 18),
              label: const Text(
                'Tutup Paksa Overlay Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForceStopReason(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  DATA MODEL UNTUK FITUR UNGGULAN
// ════════════════════════════════════════════════════════════════

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}
