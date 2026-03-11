// lib/features/screenshot/presentation/screenshot_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget untuk preview screenshot yang diambil
class ScreenshotPreview extends StatelessWidget {
  final File imageFile;
  final VoidCallback? onAnalyze;
  final VoidCallback? onDiscard;

  const ScreenshotPreview({
    super.key,
    required this.imageFile,
    this.onAnalyze,
    this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview gambar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              imageFile,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (onDiscard != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDiscard,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade400),
                      ),
                    ),
                  ),
                if (onDiscard != null && onAnalyze != null)
                  const SizedBox(width: 12),
                if (onAnalyze != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAnalyze,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Analisis AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
