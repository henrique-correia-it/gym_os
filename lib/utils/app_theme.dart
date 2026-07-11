import 'package:flutter/material.dart';

class AppTheme {
  // Tema Claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00C853),
        secondary: Color(0xFF00BFA5),
        surface: Colors.white,
        onSurface: Colors.black87,
        onSurfaceVariant: Colors.black54,
        error: Color(0xFFB00020),
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Tema Escuro
  static ThemeData darkTheme(String mode) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor:
          mode == "amoled" ? Colors.black : const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00E676),
        secondary: const Color(0xFF03DAC6),
        surface: mode == "amoled"
            ? const Color(0xFF080808)
            : const Color(0xFF1E1E1E),
        error: const Color(0xFFCF6679),
      ),
      fontFamily: 'Roboto',
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: const Color(0xFF1E1E1E),
        headerForegroundColor: const Color(0xFF00E676),
        backgroundColor:
            mode == "amoled" ? Colors.black : const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
