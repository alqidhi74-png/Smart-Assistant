import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Visual size for [AppLoadingIndicator] (Cupertino, same family as pull-to-refresh).
enum AppLoadingSize {
  /// Full-page / scaffold (radius 14, theme primary).
  page,

  /// Buttons and compact rows (radius 10).
  inline,
}

/// Unified loading spinner: [CupertinoActivityIndicator] + [ColorScheme.primary].
/// Use [AppLoadingSize.inline] on colored buttons; set [color] when it must contrast (e.g. white on primary).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingSize.page,
    this.color,
  });

  final AppLoadingSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = switch (size) {
      AppLoadingSize.page => 14.0,
      AppLoadingSize.inline => 10.0,
    };
    return CupertinoActivityIndicator(
      radius: radius,
      color: color ?? theme.colorScheme.primary,
    );
  }
}

/// Centers [AppLoadingIndicator] for full-screen loading states.
class IosStyleLoading extends StatelessWidget {
  const IosStyleLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppLoadingIndicator(size: AppLoadingSize.page),
    );
  }
}

/// Full-screen loading indicator using [OverlayEntry] — not [showDialog] —
/// so auth rebuilds / route swaps cannot duplicate [Navigator] global keys.
class LoadingOverlay {
  LoadingOverlay._();

  static OverlayEntry? _entry;
  static int _refCount = 0;

  static void show(BuildContext context) {
    _refCount++;
    if (_entry != null) return;
    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlay == null) {
      if (_refCount > 0) _refCount--;
      return;
    }

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: ModalBarrier(
                color: Colors.black38,
                dismissible: false,
              ),
            ),
            Center(
              child: AppLoadingIndicator(
                size: AppLoadingSize.page,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
  }

  /// Removes the overlay; safe to call multiple times or without a prior [show].
  static void hide() {
    if (_refCount > 0) {
      _refCount--;
    }
    if (_refCount > 0) return;
    _entry?.remove();
    _entry = null;
  }
}
