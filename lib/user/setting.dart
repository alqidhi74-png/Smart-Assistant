import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../changepassword.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../providers/theme_provider.dart';
import '../core/utils.dart';
import 'help.dart';
import 'profile.dart';
import 'about_app.dart';
import 'privacy_policy.dart';

class SettingPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;
  final String? fullName;

  const SettingPage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
    this.fullName,
  });

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Future<void> _logout() async {
    await AccountActions.showLogoutChoiceAndExecute(context);
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = Localizations.localeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final displayName =
        (widget.fullName != null && widget.fullName!.trim().isNotEmpty)
            ? widget.fullName!.trim()
            : localizations.profile;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading:
            Navigator.of(context).canPop()
                ? BackButton(color: primaryText)
                : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              _CardContainer(
                backgroundColor: cardColor,
                borderColor: borderColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cardColor,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: localizations.account,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    label: localizations.profile,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ProfilePage(fullName: widget.fullName),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: localizations.changePassword,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChangePasswordScreen(
                                onLanguageChanged: widget.onLanguageChanged,
                                currentLocale: currentLocale,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: localizations.application,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  _SettingsTile(
                    icon: Icons.language,
                    label: localizations.language,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageDisplayName(currentLocale),
                          style: TextStyle(color: secondaryText),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, color: secondaryText),
                      ],
                    ),
                    onTap: () {
                      showAppLanguageSheet(
                        context,
                        onLanguageChanged: widget.onLanguageChanged,
                      );
                    },
                  ),
                  Consumer<ThemeNotifier>(
                    builder: (context, themeNotifier, _) {
                      return _SettingsTile(
                        icon: Icons.dark_mode_outlined,
                        label: localizations.darkMode,
                        iconColor: primaryText,
                        textColor: primaryText,
                        trailingColor: secondaryText,
                        trailing: Switch(
                          value: themeNotifier.isDarkMode,
                          onChanged: (value) {
                            themeNotifier.setThemeMode(value);
                          },
                        ),
                        onTap: () {
                          themeNotifier.toggleTheme();
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: localizations.other,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline,
                    label: localizations.help,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpPage()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: localizations.aboutApp,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppPage(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    label: localizations.privacyPolicy,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(localizations.logout),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  const _CardContainer({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final Color trailingColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
    required this.textColor,
    required this.trailingColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: trailingColor),
      onTap: onTap,
    );
  }
}
