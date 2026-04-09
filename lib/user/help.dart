import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../utils/app_snackbar.dart';

/// Oman support line (local display); E.164 used for tel/sms URIs.
const String _kSupportPhoneLocal = '91208200';
const String _kSupportPhoneE164 = '+968$_kSupportPhoneLocal';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _openExternalUrl(
    BuildContext context,
    AppLocalizations loc,
    String url,
  ) async {
    final uri = Uri.parse(url);
    try {
      if (!await canLaunchUrl(uri)) {
        if (context.mounted) {
          AppSnackBar.showError(context, loc.helpCouldNotOpenLink);
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (context.mounted) {
          AppSnackBar.showError(context, loc.helpCouldNotOpenLink);
        }
      }
    }
  }

  void _showPhoneOptions(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : AppColors.textDark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    loc.helpChooseContactMethod,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(loc.helpCallPhone),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openExternalUrl(context, loc, 'tel:$_kSupportPhoneE164');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: Text(loc.helpSendSms),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openExternalUrl(context, loc, 'sms:$_kSupportPhoneE164');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          localizations.help,
          style: TextStyle(color: titleColor),
        ),
        backgroundColor: background,
        foregroundColor: titleColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: titleColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              _InfoCard(
                title: localizations.contactUs,
                child: Column(
                  children: [
                    _ContactRow(
                      icon: Icons.phone,
                      label: localizations.phone,
                      value: _kSupportPhoneLocal,
                      onTap: () => _showPhoneOptions(context, localizations),
                    ),
                    const SizedBox(height: 8),
                    _ContactRow(
                      icon: Icons.email,
                      label: localizations.email,
                      value: 'Mohammed@gmail.com',
                      onTap:
                          () => _openExternalUrl(
                            context,
                            localizations,
                            'mailto:Mohammed@gmail.com',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: localizations.faq,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FaqItem(
                      question: localizations.faqUploadInvoice,
                      answer: localizations.faqUploadInvoiceAnswer,
                    ),
                    const SizedBox(height: 12),
                    _FaqItem(
                      question: localizations.faqTrackConsumption,
                      answer: localizations.faqTrackConsumptionAnswer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final titleColor = isDark ? Colors.white : AppColors.textDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    final row = Row(
      children: [
        Icon(icon, size: 18, color: secondaryText),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: secondaryText)),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: primaryText,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryText),
        ),
        const SizedBox(height: 6),
        Text(answer, style: TextStyle(color: secondaryText)),
      ],
    );
  }
}
