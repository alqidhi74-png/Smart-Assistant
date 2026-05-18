import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/language.dart';

/// Supported app locales: English and Arabic only.
Locale normalizeSupportedLocale(Locale locale) {
  return locale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
}

String languageDisplayName(Locale locale) {
  switch (normalizeSupportedLocale(locale).languageCode) {
    case 'ar':
      return 'العربية';
    case 'en':
    default:
      return 'English';
  }
}

/// Bottom sheet to pick Arabic or English (same options as user settings).
Future<void> showAppLanguageSheet(
  BuildContext context, {
  required void Function(Locale)? onLanguageChanged,
}) async {
  final localizations =
      AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
  final currentEffective =
      normalizeSupportedLocale(Localizations.localeOf(context));
  final selected = await showModalBottomSheet<Locale>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              localizations.language,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.languageArabic),
              trailing:
                  currentEffective.languageCode == 'ar'
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
              onTap: () => Navigator.pop(context, const Locale('ar')),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.languageEnglish),
              trailing:
                  currentEffective.languageCode == 'en'
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
              onTap: () => Navigator.pop(context, const Locale('en')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (selected != null) {
    onLanguageChanged?.call(selected);
  }
}
