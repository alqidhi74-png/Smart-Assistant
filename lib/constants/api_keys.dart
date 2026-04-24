class ApiKeys {
  /// Set at compile time, e.g.:
  /// flutter run --dart-define=OPENROUTER_API_KEY=your_key
  static const String openRouterKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
}
