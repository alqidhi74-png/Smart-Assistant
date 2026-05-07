class ApiKeys {
  /// Preferred: pass at compile time with:
  /// `flutter run --dart-define=OPENROUTER_API_KEY=your_key`
  /// This fallback lets the chatbot work without extra run flags.
  static const String openRouterKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue:
        '',
  );
}
