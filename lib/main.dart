import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth_gate.dart';
import 'constants/language.dart';
import 'providers/theme_provider.dart';
import 'core/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorReporter.install();
  await Firebase.initializeApp();

  final themeNotifier = ThemeNotifier();
  await themeNotifier.initializeTheme();

  runApp(MyApp(themeNotifier: themeNotifier));
}

class MyApp extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const MyApp({super.key, required this.themeNotifier});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.themeNotifier.addListener(_onThemeChanged);
    _loadLanguage();
  }

  @override
  void dispose() {
    widget.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final locale = await LanguageService.getCurrentLanguage();
    setState(() => _locale = locale);
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguageService.setLanguage(locale);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeNotifier>.value(
      value: widget.themeNotifier,
      child: MaterialApp(
        key: const ValueKey<String>('root_material_app'),
        title: 'Smart Assistant',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        theme: ThemeNotifier.getLightTheme(),
        darkTheme: ThemeNotifier.getDarkTheme(),
        themeMode: widget.themeNotifier.themeMode,
        home: AuthGate(
          onLanguageChanged: _changeLanguage,
          currentLocale: _locale,
        ),
      ),
    );
  }
}
