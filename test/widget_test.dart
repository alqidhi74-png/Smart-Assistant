import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant/main.dart';
import 'package:smart_assistant/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyApp يُبنى مع ThemeNotifier', (WidgetTester tester) async {
    final themeNotifier = ThemeNotifier();
    await themeNotifier.initializeTheme();

    await tester.pumpWidget(MyApp(themeNotifier: themeNotifier));
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
