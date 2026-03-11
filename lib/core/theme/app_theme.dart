// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ════════════════════════════════════════════════════════════════
  //  WARNA DASAR
  // ════════════════════════════════════════════════════════════════

  /// Biru utama — warna brand aplikasi
  static const Color primaryColor = Color(0xFF2979FF);

  /// Biru gelap untuk gradient bawah
  static const Color primaryDark = Color(0xFF1A4FBF);

  /// Biru sangat gelap untuk hover / pressed state
  static const Color primaryDeep = Color(0xFF0D2E80);

  /// Cyan accent — dipakai untuk status aktif & highlight
  static const Color accentColor = Color(0xFF00E5FF);

  /// Cyan lebih redup untuk border & badge background
  static const Color accentMuted = Color(0xFF0097A7);

  // ── Background & Surface ─────────────────────────────────────────

  /// Latar belakang utama — hitam pekat hampir murni
  static const Color backgroundColor = Color(0xFF080810);

  /// Permukaan sedikit lebih terang dari background (app bar, drawer)
  static const Color surfaceColor = Color(0xFF10101C);

  /// Card / container — satu tingkat lebih terang dari surface
  static const Color cardColor = Color(0xFF181828);

  /// Card elevated — untuk dialog atau sheet
  static const Color cardElevated = Color(0xFF1E1E32);

  /// Warna border halus
  static const Color borderColor = Color(0xFF252540);

  /// Warna border saat fokus / aktif
  static const Color borderActive = Color(0xFF2979FF);

  // ── Teks ────────────────────────────────────────────────────────

  /// Teks utama — putih hangat, tidak menyilaukan
  static const Color textPrimary = Color(0xFFF0F0FA);

  /// Teks sekunder — abu-abu medium
  static const Color textSecondary = Color(0xFF8888AA);

  /// Teks tersier / placeholder
  static const Color textTertiary = Color(0xFF55557A);

  // ── Status Colors ────────────────────────────────────────────────

  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color errorColor = Color(0xFFFF3D57);
  static const Color infoColor = Color(0xFF40C4FF);

  // ════════════════════════════════════════════════════════════════
  //  GRADIENTS (reusable)
  // ════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient heroGradient = LinearGradient(
    colors: [
      primaryColor.withOpacity(0.18),
      accentColor.withOpacity(0.06),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient = LinearGradient(
    colors: [
      cardColor,
      cardElevated,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════
  //  SHADOWS
  // ════════════════════════════════════════════════════════════════

  static List<BoxShadow> primaryGlow({double intensity = 0.45}) => [
        BoxShadow(
          color: primaryColor.withOpacity(intensity),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> accentGlow({double intensity = 0.55}) => [
        BoxShadow(
          color: accentColor.withOpacity(intensity),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> deepShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.55),
      blurRadius: 28,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.10),
      blurRadius: 40,
      spreadRadius: 2,
    ),
  ];

  // ════════════════════════════════════════════════════════════════
  //  BORDER RADIUS
  // ════════════════════════════════════════════════════════════════

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 28.0;

  static BorderRadius get brSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get brMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get brLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get brXL => BorderRadius.circular(radiusXL);

  // ════════════════════════════════════════════════════════════════
  //  THEME DATA
  // ════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Color Scheme ────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.black,
        surface: surfaceColor,
        onSurface: textPrimary,
        error: errorColor,
        onError: Colors.white,
        outline: borderColor,
        surfaceContainerHighest: cardElevated,
      ),

      scaffoldBackgroundColor: backgroundColor,

      // ── AppBar ──────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),

      // ── ElevatedButton ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── Dialog ──────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardElevated,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── BottomSheet ─────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXL),
          ),
        ),
        dragHandleColor: borderColor,
        dragHandleSize: Size(40, 4),
      ),

      // ── SnackBar ─────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardElevated,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: borderColor),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // ── Switch ───────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return borderColor;
        }),
      ),

      // ── Checkbox ─────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        side: const BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ─────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
        ),
      ),

      // ── IconButton ───────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          highlightColor: primaryColor.withOpacity(0.12),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withOpacity(0.20),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Progress Indicator ───────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),

      // ── Tooltip ──────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardElevated,
          borderRadius: BorderRadius.circular(radiusSmall),
          border: const Border.fromBorderSide(
            BorderSide(color: borderColor),
          ),
        ),
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── ScrollBar ────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderColor),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),

      // ── Text Theme ───────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: textPrimary, fontSize: 57, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: textPrimary, fontSize: 45, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: textPrimary, fontSize: 36, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textPrimary, fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(
            color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(
            color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            color: textTertiary, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
