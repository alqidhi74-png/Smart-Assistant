import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../utils/app_transitions.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'dark_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _initialized;

  Future<void> initializeTheme() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _initialized = true;
      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.light;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(bool isDark) async {
    if ((isDark && _themeMode == ThemeMode.dark) ||
        (!isDark && _themeMode == ThemeMode.light)) {
      return;
    }
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode != ThemeMode.dark);
  }

  static ThemeData getLightTheme() {
    const primary = Color(0xFF1F6EBC);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: const Color(0xFFF5F7FA),
        onSurface: const Color(0xFF1A1A1A),
        surfaceContainerHighest: Colors.white,
        outline: const Color(0xFFDADCE0),
        error: const Color(0xFFE63946),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F6EBC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 16),
        hintStyle: const TextStyle(color: Color(0xFF5C5C5C)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.error,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlideFadePageTransitionsBuilder(),
          TargetPlatform.iOS: SlideFadePageTransitionsBuilder(),
          TargetPlatform.windows: SlideFadePageTransitionsBuilder(),
          TargetPlatform.macOS: SlideFadePageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData getDarkTheme() {
    const primary = Color(0xFF4A9AE8);
    const surface = Color(0xFF121212);
    const surfaceVariant = Color(0xFF1E1E1E);
    const outline = Color(0xFF3A3A3A);
    const onSurface = Color(0xFFE8E8E8);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: const Color(0xFF0A1628),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        outline: outline,
        error: const Color(0xFFE63946),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F6EBC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        labelStyle: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 16),
        hintStyle: const TextStyle(color: Color(0xFFD0D0D0)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.error,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlideFadePageTransitionsBuilder(),
          TargetPlatform.iOS: SlideFadePageTransitionsBuilder(),
          TargetPlatform.windows: SlideFadePageTransitionsBuilder(),
          TargetPlatform.macOS: SlideFadePageTransitionsBuilder(),
        },
      ),
    );
  }
}
