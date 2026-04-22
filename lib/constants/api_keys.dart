import 'secrets.dart';

class ApiKeys {
  static const String openRouterKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: Secrets.openRouterKey,
  );
}
