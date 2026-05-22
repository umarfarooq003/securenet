import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SecureNet Design System
/// Primary palette: Deep Navy (#0A1628) + Electric Teal (#00D4AA)
/// Accent: Amber (#F59E0B) for warnings, Rose (#F43F5E) for danger
class AppTheme {
  // ── Brand colours ────────────────────────────────────────────────────────────
  static const Color brandTeal   = Color(0xFF00D4AA);
  static const Color brandNavy   = Color(0xFF0A1628);
  static const Color brandAmber  = Color(0xFFF59E0B);
  static const Color brandRose   = Color(0xFFF43F5E);
  static const Color brandPurple = Color(0xFF7C3AED);

  // Status colours (shared)
  static const Color statusGreen    = Color(0xFF10B981);
  static const Color statusAmber    = Color(0xFFF59E0B);
  static const Color statusRed      = Color(0xFFEF4444);
  static const Color statusBlue     = Color(0xFF3B82F6);
  static const Color statusPurple   = Color(0xFF8B5CF6);

  // ── Light scheme ─────────────────────────────────────────────────────────────
  static ThemeData light() {
    const seed = Color(0xFF0E7490);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF0E7490),
      onPrimary: Colors.white,
      secondary: const Color(0xFF00B4D8),
      tertiary: const Color(0xFF7C3AED),
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF0F172A),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    );
    return _build(scheme, Brightness.light);
  }

  // ── Dark scheme ──────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandTeal,
      brightness: Brightness.dark,
      primary: brandTeal,
      onPrimary: brandNavy,
      secondary: const Color(0xFF22D3EE),
      tertiary: brandPurple,
      surface: const Color(0xFF0D1B2A),
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFF1E2D3D),
      outline: const Color(0xFF2D4A6B),
      outlineVariant: const Color(0xFF1A3248),
      error: brandRose,
    );
    return _build(scheme, Brightness.dark);
  }

  // ── Builder ──────────────────────────────────────────────────────────────────
  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base   = isDark ? ThemeData.dark() : ThemeData.light();

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge:  GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -1.5),
      displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium:GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.25),
      headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.25),
      titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelSmall:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : scheme.surface,
        foregroundColor: scheme.onSurface,
        shadowColor: scheme.outline.withOpacity(0.2),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),

      // ── Card ─────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: isDark ? const Color(0xFF132032) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF1E3A52)
                : const Color(0xFFE8EDF2),
            width: 1,
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.06),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1A2D3F)
            : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.4)),
        prefixIconColor: scheme.primary,
      ),

      // ── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Navigation Bar ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        indicatorColor: scheme.primary.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(color: scheme.onSurface.withOpacity(0.55), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.55),
          );
        }),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Drawer ───────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        width: 285,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: scheme.primary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,           // ← explicit: dark text in light, light in dark
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurface.withOpacity(0.6),
        ),
      ),

      // ── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary.withOpacity(0.35);
          return scheme.outline.withOpacity(0.4);
        }),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withOpacity(0.1),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? const Color(0xFF1E3A52) : const Color(0xFF1E293B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        elevation: 4,
      ),

      // ── Divider ──────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),

      // ── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Status colour helpers ─────────────────────────────────────────────────────
extension StatusColors on BuildContext {
  Color get statusGreen  => AppTheme.statusGreen;
  Color get statusAmber  => AppTheme.statusAmber;
  Color get statusRed    => AppTheme.statusRed;
  Color get statusBlue   => AppTheme.statusBlue;
  Color get statusPurple => AppTheme.statusPurple;
}