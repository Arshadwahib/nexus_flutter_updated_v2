// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── Color Palette ───────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFD4D4D4);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey700 = Color(0xFF404040);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);

  // Accent
  static const Color accent = Color(0xFF1D9BF0);      // Twitter blue
  static const Color accentGold = Color(0xFFFFD700);  // Verified gold
  static const Color danger = Color(0xFFFF3040);
  static const Color success = Color(0xFF00BA7C);
  static const Color adminBlue = Color(0xFF1D9BF0);

  // ─── Light Theme ─────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: white,
      colorScheme: const ColorScheme.light(
        primary: black,
        secondary: accent,
        surface: white,
        background: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: black,
        onBackground: black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: grey200,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: 'SF Pro Display',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: black,
        unselectedItemColor: grey400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: black,
        unselectedLabelColor: grey400,
        indicatorColor: black,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: grey200,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: grey400, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: grey200, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: grey200,
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey100,
        selectedColor: black,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: grey200, width: 0.5),
        ),
      ),
      fontFamily: 'SF Pro Text',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: black),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: black),
        displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: black),
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: black),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: black),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: black),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: black),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: black),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: black),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: black, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: black, height: 1.4),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: grey500, height: 1.4),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: black),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: grey500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: grey400),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: white,
        secondary: accent,
        surface: grey900,
        background: black,
        onPrimary: black,
        onSecondary: white,
        onSurface: white,
        onBackground: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: grey800,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: black,
        selectedItemColor: white,
        unselectedItemColor: grey600,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: white,
        unselectedLabelColor: grey600,
        indicatorColor: white,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: grey800,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey800, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: grey600, fontSize: 15),
        labelStyle: const TextStyle(color: grey400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(color: grey700, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: grey800,
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey900,
        selectedColor: white,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      cardTheme: CardTheme(
        color: grey900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: grey800, width: 0.5),
        ),
      ),
      fontFamily: 'SF Pro Text',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: white),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: white),
        displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: white),
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: white),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: white),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: white),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: white),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: white),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: white),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: white, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: white, height: 1.4),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: grey500, height: 1.4),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: grey500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: grey600),
      ),
    );
  }
}
