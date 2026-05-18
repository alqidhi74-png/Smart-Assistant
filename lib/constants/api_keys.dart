class ApiKeys {
  /// Set at compile time, e.g.:
  /// `flutter run --dart-define=OPENROUTER_API_KEY=your_key`
  /// or `flutter run --dart-define-from-file=dart_defines.json` (see README).
  static const String openRouterKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
}
