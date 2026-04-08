import 'package:flutter/material.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(localizations.privacyPolicy),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Text(
            localizations.privacyPolicyContent,
            style: TextStyle(fontSize: 15, height: 1.6, color: textColor),
          ),
        ),
      ),
    );
  }
}
