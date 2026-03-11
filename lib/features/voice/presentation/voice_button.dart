// lib/features/voice/presentation/voice_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/voice_service.dart';

/// Tombol mikrofon yang bisa dipasang di mana saja
/// Callback onResult dipanggil saat user selesai berbicara
class VoiceButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final double size;

  const VoiceButton({
    super.key,
    required this.onResult,
    this.size = 48,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isListening) {
      final text = await VoiceService.stopListening();
      setState(() => _isListening = false);
      if (text != null && text.isNotEmpty) {
        widget.onResult(text);
      }
    } else {
      setState(() => _isListening = true);
      await VoiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Colors.red.withOpacity(0.9)
                    : AppTheme.surfaceColor,
                border: Border.all(
                  color: _isListening ? Colors.red : AppTheme.primaryColor,
                  width: 2,
                ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: _isListening ? Colors.white : AppTheme.primaryColor,
                size: widget.size * 0.45,
              ),
            ),
          );
        },
      ),
    );
  }
}
