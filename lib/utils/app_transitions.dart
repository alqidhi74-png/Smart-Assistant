import 'package:flutter/material.dart';

class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutCubic;

    final slideTween = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: curve));

    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
    );
  }
}
