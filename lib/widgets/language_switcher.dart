import 'package:flutter/material.dart';
import '../constants/colors.dart';

class LanguageSwitcher extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onLanguageChanged;

  const LanguageSwitcher({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: AppColors.textOnDark),
      onSelected: (Locale locale) {
        onLanguageChanged(locale);
      },
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<Locale>(
              value: const Locale('ar'),
              child: Row(
                children: [
                  const Text('العربية'),
                  if (currentLocale.languageCode == 'ar')
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check, size: 16),
                    ),
                ],
              ),
            ),
            PopupMenuItem<Locale>(
              value: const Locale('en'),
              child: Row(
                children: [
                  const Text('English'),
                  if (currentLocale.languageCode == 'en')
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check, size: 16),
                    ),
                ],
              ),
            ),
          ],
    );
  }
}
