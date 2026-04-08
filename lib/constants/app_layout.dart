import 'package:flutter/material.dart';

/// Shared page padding and responsive breakpoints (aligned with My Bills / Home).
abstract final class AppLayout {
  AppLayout._();

  static const double pagePaddingH = 10;
  static const double pagePaddingV = 8;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pagePaddingH,
    vertical: pagePaddingV,
  );

  /// Narrow screens: e.g. admin overview grid becomes single column.
  static const double breakpointNarrow = 420;

  /// Wide enough to show user home charts side-by-side.
  static const double breakpointWideCharts = 760;

  /// Typical max width for centered auth forms.
  static const double formMaxWidth = 420;
}
