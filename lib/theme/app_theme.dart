import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/theme/app_tokens.dart';

class AppTheme {
  // Colors
  static const primaryColor = Colors.deepPurple;

  // Text Themes
  static final TextTheme _appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.oswald(fontSize: 45, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.oswald(fontSize: 36, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.w500),
      headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w500),
      headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w500),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.openSans(fontSize: 16),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
      bodySmall: GoogleFonts.openSans(fontSize: 12),
      labelLarge: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.bold),
      labelMedium: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.bold),
      labelSmall: GoogleFonts.openSans(fontSize: 11, fontWeight: FontWeight.bold),
  );

  // Themes
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: _appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: _appTextTheme.headlineSmall?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: _appTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTokens.elevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: _appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: _appTextTheme.headlineSmall?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: primaryColor.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: _appTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTokens.elevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
      ),
    );
  }
}
