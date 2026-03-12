// lib/features/overlay/presentation/overlay_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../ai_chat/presentation/mini_chat_panel.dart';

/// Widget yang ditampilkan sebagai floating bubble di atas semua aplikasi.
///
/// Dua mode:
///   - Bubble kecil (65×65) — idle, bisa di-drag
///   - Panel chat (320×500) — expanded saat bubble di-tap
///
/// CATATAN: Jaga widget ini seminimal mungkin di overlay context.
/// Jangan tambahkan Navigator, Dialog, atau widget yang bergantung
/// pada MaterialApp ancestor yang bukan dari overlay_entry.dart.
class FloatingBubbleWidget extends StatefulWidget {
  const FloatingBubbleWidget({super.key});

  @override
  State<FloatingBubbleWidget> createState() => _FloatingBubbleWidgetState();
}

class _FloatingBubbleWidgetState extends State<FloatingBubbleWidget>
    with TickerProviderStateMixin {
  bool _isPanelOpen = false;

  // ── Flag untuk mencegah toggle dipanggil saat sedang resize ─────
  bool _isResizing = false;

  // ── Animasi scale/fade saat panel muncul ─────────────────────────
  late AnimationController _panelController;
  late Animation<double> _panelScale;
  late Animation<double> _panelOpacity;

  // ── Pulse idle bubble ────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // ── Ring ripple luar bubble ──────────────────────────────────────
  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  // ── Rotasi ikon saat tap ─────────────────────────────────────────
  late AnimationController _rotateController;
  late Animation<double> _rotateAngle;

  @override
  void initState() {
    super.initState();

    // Panel expand/collapse
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelScale = CurvedAnimation(
      parent: _panelController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    );
    _panelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOut),
    );

    // Bubble pulse (idle breathing)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ring ripple
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _rippleScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Icon rotation on tap
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _rotateAngle = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  TOGGLE PANEL
  // ════════════════════════════════════════════════════════════════

  /// Toggle antara mode bubble kecil dan panel chat.
  ///
  /// Urutan operasi saat MEMBUKA panel:
  ///   1. Update state → rebuild ke panel (pakai ukuran saat ini dulu)
  ///   2. Resize overlay ke ukuran panel
  ///   3. Jalankan animasi panel masuk
  ///
  /// Urutan operasi saat MENUTUP panel:
  ///   1. Jalankan animasi panel keluar
  ///   2. Setelah animasi selesai → resize overlay ke ukuran bubble
  ///   3. Update state → rebuild ke bubble
  void _togglePanel() {
    if (_isResizing) return;

    if (!_isPanelOpen) {
      // ── Buka panel ──────────────────────────────────────────────
      _pulseController.stop();
      _rippleController.stop();
      _rotateController.forward();

      // Resize dulu SEBELUM setState agar Flutter tidak render panel
      // dalam bounding box bubble yang kecil
      _isResizing = true;
      FlutterOverlayWindow.resizeOverlay(
        AppConstants.panelWidth.toInt(),
        AppConstants.panelHeight.toInt(),
        true,
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _isPanelOpen = true;
          _isResizing = false;
        });
        _panelController.forward();
      }).catchError((_) {
        _isResizing = false;
      });
    } else {
      // ── Tutup panel ─────────────────────────────────────────────
      _panelController.reverse().then((_) {
        if (!mounted) return;
        _isResizing = true;
        FlutterOverlayWindow.resizeOverlay(
          AppConstants.bubbleSize.toInt(),
          AppConstants.bubbleSize.toInt(),
          true,
        ).then((_) {
          if (!mounted) return;
          setState(() {
            _isPanelOpen = false;
            _isResizing = false;
          });
          _pulseController.repeat(reverse: true);
          _rippleController.repeat();
          _rotateController.reverse();
        }).catchError((_) {
          if (mounted) {
            setState(() {
              _isPanelOpen = false;
              _isResizing = false;
            });
          }
        });
      });
    }
  }

  Future<void> _closeBubble() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Tidak pakai AnimatedSwitcher — berbahaya saat size berubah drastis
    // antara 65×65 (bubble) dan 320×500 (panel) di overlay context.
    return Material(
      color: Colors.transparent,
      child: _isPanelOpen ? _buildPanel() : _buildBubble(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BUBBLE (MODE KECIL)
  // ════════════════════════════════════════════════════════════════

  Widget _buildBubble() {
    return GestureDetector(
      key: const ValueKey('bubble'),
      onTap: _togglePanel,
      onLongPress: _closeBubble,
      child: SizedBox(
        width: AppConstants.bubbleSize,
        height: AppConstants.bubbleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Ring ripple luar ─────────────────────────────────
            AnimatedBuilder(
              animation: _rippleController,
              builder: (_, __) => Transform.scale(
                scale: _rippleScale.value,
                child: Opacity(
                  opacity: _rippleOpacity.value,
                  child: Container(
                    width: AppConstants.bubbleSize - 12,
                    height: AppConstants.bubbleSize - 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Lingkaran utama dengan pulse ─────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: _pulseScale.value,
                child: Opacity(
                  opacity: _pulseOpacity.value,
                  child: child,
                ),
              ),
              child: Container(
                width: AppConstants.bubbleSize - 12,
                height: AppConstants.bubbleSize - 12,
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
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _rotateAngle,
                  child: const Icon(
                    Icons.assistant_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            // ── Titik indikator aktif (pojok kanan atas) ─────────
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor,
                  border: Border.all(
                    color: AppTheme.backgroundColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.7),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PANEL (MODE EXPANDED)
  // ════════════════════════════════════════════════════════════════

  Widget _buildPanel() {
    return ScaleTransition(
      key: const ValueKey('panel'),
      scale: _panelScale,
      child: FadeTransition(
        opacity: _panelOpacity,
        child: Container(
          width: AppConstants.panelWidth,
          height: AppConstants.panelHeight,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 28,
                spreadRadius: 6,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.12),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                _buildPanelHeader(),
                const Expanded(child: MiniChatPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.20),
            AppTheme.accentColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Ikon & nama ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.assistant_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Powered by Gemini & ChatGPT',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Status dot ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.8),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'AKTIF',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Tombol minimize ──────────────────────────────────────
          _HeaderButton(
            icon: Icons.remove_rounded,
            tooltip: 'Minimize',
            onTap: _togglePanel,
          ),
          const SizedBox(width: 4),

          // ── Tombol close ─────────────────────────────────────────
          _HeaderButton(
            icon: Icons.close_rounded,
            tooltip: 'Tutup',
            onTap: _closeBubble,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  HELPER: TOMBOL HEADER PANEL
// ════════════════════════════════════════════════════════════════

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? Colors.red : AppTheme.textSecondary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _pressed ? color.withOpacity(0.18) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(widget.icon, color: color, size: 16),
      ),
    );
  }
}
