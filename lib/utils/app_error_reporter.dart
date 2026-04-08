import 'package:flutter/foundation.dart';

/// Central hooks for uncaught errors. In debug, logs to console; plug Crashlytics here for release.
abstract final class AppErrorReporter {
  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
        if (details.stack != null) {
          debugPrint(details.stack.toString());
        }
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('[async] $error');
        debugPrint(stack.toString());
      }
      return true;
    };
  }

  static void debug(String context, Object? error, [StackTrace? stack]) {
    if (!kDebugMode || error == null) return;
    debugPrint('[$context] $error');
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }
}
