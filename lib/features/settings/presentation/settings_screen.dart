// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _geminiKeyController = TextEditingController();
  final _openAiKeyController = TextEditingController();

  String _selectedProvider = 'gemini';
  bool _isGeminiObscured = true;
  bool _isOpenAiObscured = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _geminiKeyController.text = StorageService.geminiApiKey;
    _openAiKeyController.text = StorageService.openAiApiKey;
    _selectedProvider = StorageService.aiProvider;
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _openAiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await StorageService.setGeminiApiKey(_geminiKeyController.text.trim());
    await StorageService.setOpenAiApiKey(_openAiKeyController.text.trim());
    await StorageService.setAiProvider(_selectedProvider);

    if (mounted) {
      setState(() => _isSaved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSaved = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Pengaturan berhasil disimpan!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppTheme.textSecondary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pengaturan',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner status API key ──────────────────────────────
            _buildInfoBanner(),
            const SizedBox(height: 24),

            // ── Pilihan AI Provider ────────────────────────────────
            _buildSectionHeader(
              icon: Icons.smart_toy_outlined,
              title: 'AI Provider Aktif',
              subtitle: 'Pilih engine AI yang digunakan saat chat',
            ),
            const SizedBox(height: 12),
            _buildProviderSelector(),
            const SizedBox(height: 28),

            // ── Gemini API Key ─────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.auto_awesome,
              title: 'Gemini API Key',
              subtitle: 'aistudio.google.com — Gratis & tanpa kartu kredit',
              iconColor: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 10),
            _buildApiKeyInput(
              controller: _geminiKeyController,
              hintText: 'AIza...',
              isObscured: _isGeminiObscured,
              onToggleObscure: () =>
                  setState(() => _isGeminiObscured = !_isGeminiObscured),
              accentColor: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 8),
            _buildApiKeyHelp(
              isGemini: true,
              accentColor: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 24),

            // ── OpenAI API Key ─────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.psychology_outlined,
              title: 'OpenAI API Key',
              subtitle: 'platform.openai.com — Berbayar (pay-as-you-go)',
              iconColor: const Color(0xFF10A37F),
            ),
            const SizedBox(height: 10),
            _buildApiKeyInput(
              controller: _openAiKeyController,
              hintText: 'sk-proj-...',
              isObscured: _isOpenAiObscured,
              onToggleObscure: () =>
                  setState(() => _isOpenAiObscured = !_isOpenAiObscured),
              accentColor: const Color(0xFF10A37F),
            ),
            const SizedBox(height: 8),
            _buildApiKeyHelp(
              isGemini: false,
              accentColor: const Color(0xFF10A37F),
            ),
            const SizedBox(height: 32),

            // ── Tombol Simpan ──────────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: 20),

            // ── Tips Penggunaan ────────────────────────────────────
            _buildQuickTips(),
            const SizedBox(height: 20),

            // ── Catatan Privasi ────────────────────────────────────
            _buildPrivacyNote(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BANNER STATUS
  // ════════════════════════════════════════════════════════════════

  Widget _buildInfoBanner() {
    final hasKey = StorageService.activeApiKey.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasKey
              ? [
                  AppTheme.accentColor.withOpacity(0.12),
                  AppTheme.primaryColor.withOpacity(0.07),
                ]
              : [
                  Colors.orange.withOpacity(0.12),
                  Colors.orange.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasKey
              ? AppTheme.accentColor.withOpacity(0.30)
              : Colors.orange.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (hasKey ? AppTheme.accentColor : Colors.orange)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasKey ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: hasKey ? AppTheme.accentColor : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasKey
                      ? 'API Key Sudah Terkonfigurasi'
                      : 'API Key Diperlukan',
                  style: TextStyle(
                    color: hasKey ? AppTheme.accentColor : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasKey
                      ? 'AI chat siap digunakan. Provider aktif: '
                          '${StorageService.aiProvider.toUpperCase()}'
                      : 'Masukkan API key di bawah agar fitur AI chat berfungsi.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.4,
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
  //  SECTION HEADER
  // ════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PROVIDER SELECTOR
  // ════════════════════════════════════════════════════════════════

  Widget _buildProviderSelector() {
    return Row(
      children: [
        Expanded(
          child: _ProviderCard(
            title: 'Gemini',
            subtitle: 'Google AI\n(Gratis tersedia)',
            icon: Icons.auto_awesome,
            color: const Color(0xFF4285F4),
            isSelected: _selectedProvider == 'gemini',
            onTap: () => setState(() => _selectedProvider = 'gemini'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProviderCard(
            title: 'OpenAI',
            subtitle: 'ChatGPT\n(Berbayar)',
            icon: Icons.psychology_outlined,
            color: const Color(0xFF10A37F),
            isSelected: _selectedProvider == 'openai',
            onTap: () => setState(() => _selectedProvider = 'openai'),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  API KEY INPUT
  // ════════════════════════════════════════════════════════════════

  Widget _buildApiKeyInput({
    required TextEditingController controller,
    required String hintText,
    required bool isObscured,
    required VoidCallback onToggleObscure,
    required Color accentColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontFamily: 'monospace',
        fontSize: 13,
        letterSpacing: isObscured ? 2.0 : 0.5,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppTheme.textTertiary,
          fontFamily: 'sans-serif',
          letterSpacing: 0,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol copy (hanya muncul kalau ada teks)
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: AppTheme.textTertiary,
                tooltip: 'Salin API Key',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('API Key disalin ke clipboard'),
                      backgroundColor: AppTheme.cardColor,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    ),
                  );
                },
              ),
            // Tombol show/hide
            IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              color: AppTheme.textSecondary,
              tooltip: isObscured ? 'Tampilkan Key' : 'Sembunyikan Key',
              onPressed: onToggleObscure,
            ),
          ],
        ),
      ),
      // Perbarui state saat teks berubah agar tombol copy muncul/hilang
      onChanged: (_) => setState(() {}),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  API KEY HELP
  // ════════════════════════════════════════════════════════════════

  Widget _buildApiKeyHelp({
    required bool isGemini,
    required Color accentColor,
  }) {
    final steps = isGemini
        ? [
            'Buka aistudio.google.com di browser',
            'Login dengan akun Google kamu',
            'Klik "Get API Key" → "Create API key in new project"',
            'Salin key yang muncul dan tempel di field di atas',
          ]
        : [
            'Buka platform.openai.com di browser',
            'Login atau daftar akun baru',
            'Menu kiri → "API keys" → "Create new secret key"',
            'Salin key yang muncul dan tempel di field di atas',
          ];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: accentColor, size: 14),
              const SizedBox(width: 6),
              Text(
                isGemini
                    ? 'Cara Mendapatkan Gemini Key'
                    : 'Cara Mendapatkan OpenAI Key',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SAVE BUTTON
  // ════════════════════════════════════════════════════════════════

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _isSaved
              ? const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_isSaved ? Colors.green : AppTheme.primaryColor)
                  .withOpacity(0.40),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saveSettings,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.06),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSaved ? Icons.check_rounded : Icons.save_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSaved ? 'Tersimpan!' : 'Simpan Pengaturan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  QUICK TIPS
  // ════════════════════════════════════════════════════════════════

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppTheme.warningColor, size: 16),
              SizedBox(width: 7),
              Text(
                'Tips Penggunaan',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTipItem(
            '💡',
            'Rekomendasi: gunakan Gemini karena gratis dan tidak perlu kartu kredit.',
          ),
          _buildTipItem(
            '🔄',
            'Setelah menyimpan, matikan dan aktifkan kembali overlay agar config terbaru terkirim ke bubble.',
          ),
          _buildTipItem(
            '📋',
            'Tap ikon 👁 untuk melihat atau menyembunyikan API key yang dimasukkan.',
          ),
          _buildTipItem(
            '🔒',
            'API key tersimpan lokal dan aman — tidak pernah dikirim ke server selain Google/OpenAI.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PRIVACY NOTE
  // ════════════════════════════════════════════════════════════════

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.successColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privasi & Keamanan',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'API key kamu disimpan secara lokal di perangkat ini '
                  'menggunakan Hive (database offline). Key TIDAK pernah '
                  'dikirim ke server kami — hanya ke Google atau OpenAI '
                  'saat kamu melakukan percakapan AI.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.5,
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

// ════════════════════════════════════════════════════════════════
//  PROVIDER CARD WIDGET
// ════════════════════════════════════════════════════════════════

class _ProviderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
