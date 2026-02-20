import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primary = Color(0xFF781C2E);
  static const Color _secondary = Color(0xFF8B2635);
  static const Color _tertiary = Color(0xFF9E2F3C);
  static const Color _accent = Color(0xFFB13843);
  static const Color _background = Color(0xFFF9F6EE);

  static final _textTheme = GoogleFonts.manropeTextTheme().copyWith(
    headlineLarge: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700),
    bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
    labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _background,
    textTheme: _textTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surfaceTint: _accent,
      background: _background,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primary),
      titleTextStyle: GoogleFonts.sora(
        color: _primary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x14781C2E)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: _primary.withOpacity(0.12),
      secondarySelectedColor: _primary.withOpacity(0.18),
      labelStyle: GoogleFonts.manrope(
        color: _primary,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: StadiumBorder(side: BorderSide(color: _primary.withOpacity(0.12))),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _background,
      indicatorColor: _primary.withOpacity(0.12),
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.manrope(
          color: _primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primary, size: 26);
        }
        return const IconThemeData(color: Color(0x80781C2E), size: 24);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x1A781C2E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x1A781C2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      labelStyle: GoogleFonts.manrope(color: _primary.withOpacity(0.6)),
      prefixIconColor: _primary,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: _primary.withOpacity(0.08),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: _primary,
      contentTextStyle: GoogleFonts.manrope(color: Colors.white),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(
        0xFF781C2E,
      ), // Use Burgundy as seed even for dark mode
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  );
}
