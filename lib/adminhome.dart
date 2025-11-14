import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';

class AdminHome extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminHome({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.adminHome,
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
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.welcomeAdmin,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.adminHomePage,
              style: const TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

