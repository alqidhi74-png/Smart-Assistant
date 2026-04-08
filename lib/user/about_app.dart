import 'package:flutter/material.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final secondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(localizations.aboutAppTitle),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.bolt,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Smart Assistant',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.appVersion} $_version',
                style: TextStyle(fontSize: 14, color: secondaryColor),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  localizations.aboutAppDescription,
                  style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
