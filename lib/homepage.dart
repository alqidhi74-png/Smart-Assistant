import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';

class HomePage extends StatefulWidget {
  final String fullName;
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const HomePage({
    super.key,
    required this.fullName,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.homePage,
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          if (widget.onLanguageChanged != null)
            LanguageSwitcher(
              currentLocale: currentLocale,
              onLanguageChanged: widget.onLanguageChanged!,
            ),
        ],
      ),
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${localizations.welcome}, ${widget.fullName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.userHomePage,
              style: const TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
