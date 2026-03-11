// lib/features/ai_chat/presentation/mini_chat_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/ai_service.dart';
import '../../screenshot/domain/screenshot_service.dart';
import '../../ocr/domain/ocr_service.dart';
import '../../voice/domain/voice_service.dart';

// Provider untuk state chat
final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(),
);

final isLoadingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
  }
}

/// Panel chat mini yang muncul saat bubble ditekan
class MiniChatPanel extends ConsumerStatefulWidget {
  const MiniChatPanel({super.key});

  @override
  ConsumerState<MiniChatPanel> createState() => _MiniChatPanelState();
}

class _MiniChatPanelState extends ConsumerState<MiniChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();

  bool _isListening = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===================== ACTION HANDLERS =====================

  Future<void> _sendMessage([String? override]) async {
    final text = override ?? _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();

    // Tambah pesan user
    ref.read(chatMessagesProvider.notifier).addMessage(
          ChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
        );

    ref.read(isLoadingProvider.notifier).state = true;
    _scrollToBottom();

    try {
      final history = ref.read(chatMessagesProvider);
      final response = await _aiService.sendMessage(
        userMessage: text,
        history:
            history.sublist(0, history.length - 1), // Exclude pesan terakhir
      );

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
                role: 'assistant',
                content: response,
                timestamp: DateTime.now()),
          );
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: 'Maaf, terjadi kesalahan: $e',
              timestamp: DateTime.now(),
            ),
          );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  Future<void> _captureAndAnalyze() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      // 1. Tambah pesan user dulu agar ada feedback visual
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'user',
              content: '📷 Analisis layar saat ini',
              timestamp: DateTime.now(),
            ),
          );
      _scrollToBottom();

      // 2. Ambil screenshot
      final imageFile = await ScreenshotService.captureScreen();
      if (imageFile == null) {
        // Screenshot gagal — tampilkan pesan yang jelas kepada pengguna
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content: '⚠️ **Gagal mengambil screenshot.**\n\n'
                    'Fitur capture layar memerlukan izin tambahan di Android. '
                    'Pastikan izin "Capture Screen" sudah diberikan, '
                    'atau coba gunakan fitur chat teks secara manual.',
                timestamp: DateTime.now(),
              ),
            );
        return;
      }

      // 3. Kirim ke AI Vision
      final response = await _aiService.analyzeScreenshot(
        imageFile: imageFile,
        question:
            'Jelaskan isi layar ini secara singkat dan berguna dalam bahasa Indonesia.',
      );

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: response,
              timestamp: DateTime.now(),
            ),
          );
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: '❌ Terjadi kesalahan saat analisis layar: $e',
              timestamp: DateTime.now(),
            ),
          );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      final text = await VoiceService.stopListening();
      setState(() => _isListening = false);
      if (text != null && text.isNotEmpty) {
        await _sendMessage(text);
      } else {
        // Tidak ada teks yang dikenali — beri feedback
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content:
                    '🎤 Tidak ada suara yang terdeteksi. Silakan coba bicara lebih jelas.',
                timestamp: DateTime.now(),
              ),
            );
        _scrollToBottom();
      }
    } else {
      final initialized = await VoiceService.initialize();
      if (!initialized) {
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content:
                    '🎤 Gagal mengaktifkan mikrofon. Pastikan izin RECORD_AUDIO sudah diberikan di pengaturan aplikasi.',
                timestamp: DateTime.now(),
              ),
            );
        _scrollToBottom();
        return;
      }
      setState(() => _isListening = true);
      await VoiceService.startListening();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Column(
      children: [
        // Area pesan chat
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(messages),
        ),

        // Loading indicator
        if (isLoading)
          const LinearProgressIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.cardColor,
          ),

        // Action buttons (screenshot, voice)
        _buildActionButtons(),

        // Input area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.18),
                    AppTheme.accentColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assistant_rounded,
                color: AppTheme.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Halo! Ada yang bisa dibantu?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ketik pertanyaan, capture layar,\natau gunakan input suara.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Quick suggestion chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('📝 Rangkum teks'),
                _buildSuggestionChip('🌐 Terjemahkan'),
                _buildSuggestionChip('💡 Jelaskan kode'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        // Ambil teks tanpa emoji untuk dikirim
        final text = label.substring(label.indexOf(' ') + 1);
        _inputController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  code: const TextStyle(
                    color: AppTheme.accentColor,
                    backgroundColor: AppTheme.backgroundColor,
                    fontSize: 11,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Screenshot button
          Expanded(
            child: _ActionButton(
              icon: Icons.screenshot,
              label: 'Capture',
              onTap: _captureAndAnalyze,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          // OCR button
          Expanded(
            child: _ActionButton(
              icon: Icons.document_scanner,
              label: 'Baca Teks',
              onTap: _readScreenText,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          // Translate button
          Expanded(
            child: _ActionButton(
              icon: Icons.translate,
              label: 'Terjemah',
              onTap: _translateScreenText,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _readScreenText() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'user',
              content: '🔍 Baca teks dari layar (OCR)',
              timestamp: DateTime.now(),
            ),
          );
      _scrollToBottom();

      final imageFile = await ScreenshotService.captureScreen();
      if (imageFile == null) {
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content: '⚠️ **Gagal mengambil screenshot untuk OCR.**\n\n'
                    'Pastikan izin capture layar sudah diberikan, '
                    'atau tempel teks langsung di kolom chat untuk saya bantu baca.',
                timestamp: DateTime.now(),
              ),
            );
        return;
      }

      final text = await OcrService.extractText(imageFile);

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: text.isEmpty
                  ? '🔍 Tidak ada teks yang terdeteksi di layar saat ini.'
                  : '**Teks yang ditemukan di layar:**\n\n$text',
              timestamp: DateTime.now(),
            ),
          );
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: '❌ Gagal membaca teks: $e',
              timestamp: DateTime.now(),
            ),
          );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  Future<void> _translateScreenText() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'user',
              content: '🌐 Terjemahkan teks dari layar',
              timestamp: DateTime.now(),
            ),
          );
      _scrollToBottom();

      final imageFile = await ScreenshotService.captureScreen();
      if (imageFile == null) {
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content:
                    '⚠️ **Gagal mengambil screenshot untuk terjemahan.**\n\n'
                    'Tempel teks yang ingin diterjemahkan langsung di kolom chat, '
                    'lalu ketik "terjemahkan ke Indonesia" atau bahasa lainnya.',
                timestamp: DateTime.now(),
              ),
            );
        return;
      }

      final text = await OcrService.extractText(imageFile);
      if (text.isEmpty) {
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content:
                    '🔍 Tidak ada teks yang dapat diterjemahkan di layar saat ini.',
                timestamp: DateTime.now(),
              ),
            );
        return;
      }

      final translated = await _aiService.translateText(text, 'Indonesia');

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: '**Terjemahan (Indonesia):**\n\n$translated',
              timestamp: DateTime.now(),
            ),
          );
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: '❌ Gagal menerjemahkan: $e',
              timestamp: DateTime.now(),
            ),
          );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Voice button
          GestureDetector(
            onTap: _toggleVoice,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withOpacity(0.2)
                    : AppTheme.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: _isListening ? Colors.red : AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tanya AI...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol aksi kecil di panel
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
