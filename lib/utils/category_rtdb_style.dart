import 'package:flutter/material.dart';

/// Visual style for a category row stored under RTDB `categories/{id}`.
/// Fields: [iconCodePoint] (int), [colorArgb] (int, Flutter ARGB).
class CategoryRtdbStyle {
  final IconData icon;
  final Color cardColor;
  final Color iconTint;
  final Color badgeColor;

  const CategoryRtdbStyle({
    required this.icon,
    required this.cardColor,
    required this.iconTint,
    required this.badgeColor,
  });

  /// Icon + main color for user home stat tiles and admin overview (pie slices).
  ({IconData icon, Color color}) get overview =>
      (icon: icon, color: cardColor);

  factory CategoryRtdbStyle.fromMap(Map<dynamic, dynamic> raw, String name) {
    final iconCode = (raw['iconCodePoint'] as num?)?.toInt();
    final colorVal =
        (raw['colorArgb'] as num?)?.toInt() ?? (raw['color'] as num?)?.toInt();
    final fallback = CategoryRtdbStyle.fallbackForName(name);
    if (iconCode == null && colorVal == null) {
      return fallback;
    }
    final color =
        colorVal != null ? Color(colorVal) : fallback.cardColor;
    final icon =
        iconCode != null
            ? IconData(iconCode, fontFamily: 'MaterialIcons')
            : fallback.icon;
    return CategoryRtdbStyle._derive(icon, color);
  }

  static CategoryRtdbStyle _derive(IconData icon, Color cardColor) {
    final hsl = HSLColor.fromColor(cardColor);
    final iconTint = hsl
        .withLightness((hsl.lightness * 0.72).clamp(0.05, 0.95))
        .toColor();
    final badge = hsl
        .withLightness((hsl.lightness * 0.58).clamp(0.05, 0.95))
        .toColor();
    return CategoryRtdbStyle(
      icon: icon,
      cardColor: cardColor,
      iconTint: iconTint,
      badgeColor: badge,
    );
  }

  static CategoryRtdbStyle fallbackForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('electric') || name.contains('كهرب')) {
      return CategoryRtdbStyle._derive(
        Icons.flash_on,
        const Color(0xFFFFA25B),
      );
    }
    if (lower.contains('water') || name.contains('مياه')) {
      return CategoryRtdbStyle._derive(
        Icons.water_drop,
        const Color(0xFF63B0FF),
      );
    }
    if (lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('net') ||
        name.contains('انترنت') ||
        name.contains('إنترنت')) {
      return CategoryRtdbStyle._derive(
        Icons.wifi,
        const Color(0xFF61F26B),
      );
    }
    return CategoryRtdbStyle._derive(
      Icons.receipt_long,
      const Color(0xFFB0BEC5),
    );
  }
}

int colorToArgb(Color c) => c.toARGB32();
