import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 EXACT COLOR PALETTE
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1B5BFF);
  static const Color darkNavy = Color(0xFF0A1A2F);

  // Accent Colors
  static const Color tealAccent = Color(0xFF1BC8A6);
  static const Color electricPurple = Color(0xFF7B61FF);
  static const Color hotPink = Color(0xFFFF2E92);

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF7F9FC); // Soft beige
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGray = Color(0xFFE4E8EE);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6F7A89);

  // Semantic Colors
  static const Color success = Color(0xFF1BC47D);
  static const Color warning = Color(0xFFFFB400);
  static const Color error = Color(0xFFE54848);
  static const Color info = Color(0xFF447BFF); // Same as lighter blue variant

  // Dark Mode Variants
  static const Color darkBackground = Color(0xFF0A1A2F);
  static const Color darkSurface = Color(0xFF152238);
  static const Color darkBorder = Color(0xFF2A3F5F);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B8C4);

  // Reference Specific
  static const Color softLavender = Color(0xFFE8E4F3);

  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1B5BFF), Color(0xFF447BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF1B5BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF1BC8A6), Color(0xFF1BC47D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE54848), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFE54848), Color(0xFFFF2E92)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🎭 SHADOWS
  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
          color: const Color(0xFF6F7A89).withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2), // Darker shadow for dark mode
          offset: const Offset(0, 4),
          blurRadius: 20,
          spreadRadius: 3,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF1B5BFF).withOpacity(0.25),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // 📝 TYPOGRAPHY STYLES
  static const TextStyle bigNumber = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.0,
    letterSpacing: -1.0,
  );

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // THEMES
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: tealAccent,
        surface: cardWhite,
        background: backgroundLight,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
      ),
      fontFamily: 'Inter', // Fallback handled by system
      textTheme: TextTheme(
        displayLarge: bigNumber.copyWith(color: textDark),
        displayMedium: display.copyWith(color: textDark),
        headlineLarge: h1.copyWith(color: textDark),
        headlineMedium: h2.copyWith(color: textDark),
        titleLarge: h3.copyWith(color: textDark),
        bodyLarge: bodyLarge.copyWith(color: textDark),
        bodyMedium: body.copyWith(color: textDark),
        labelLarge: label.copyWith(color: textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: h2, // 22px Bold
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: tealAccent,
        surface: darkSurface,
        background: darkBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: bigNumber.copyWith(color: darkTextPrimary),
        displayMedium: display.copyWith(color: darkTextPrimary),
        headlineLarge: h1.copyWith(color: darkTextPrimary),
        headlineMedium: h2.copyWith(color: darkTextPrimary),
        titleLarge: h3.copyWith(color: darkTextPrimary),
        bodyLarge: bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: body.copyWith(color: darkTextPrimary),
        labelLarge: label.copyWith(color: darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
    );
  }
}
