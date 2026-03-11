// lib/features/ocr/presentation/ocr_result_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Widget untuk menampilkan hasil OCR dengan fitur copy
class OcrResultWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onSendToAi;

  const OcrResultWidget({
    super.key,
    required this.text,
    this.onSendToAi,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada teks yang ditemukan',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.document_scanner,
                    color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Teks Terdeteksi',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Copy button
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: AppTheme.textSecondary,
                  tooltip: 'Salin teks',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teks disalin!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          // Send to AI button
          if (onSendToAi != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSendToAi,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Tanya AI tentang teks ini'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
