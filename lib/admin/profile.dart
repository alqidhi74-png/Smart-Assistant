import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../changepassword.dart';
import '../utils/account_actions.dart';
import '../utils/app_language_sheet.dart';
import '../providers/theme_provider.dart';
import '../user/about_app.dart';
import '../user/profile.dart';
import '../user/privacy_policy.dart';
import '../widgets/settings_page_widgets.dart';

class AdminProfilePage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminProfilePage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String _fullName = 'Admin';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final snapshot = await dbRef.child('users/${user.uid}').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _fullName = data['fullName'] as String? ?? 'Admin';
            _email = data['email'] as String? ?? user.email ?? '';
            _phone = data['phone'] as String? ?? '';
          });
        } else {
          setState(() {
            _email = user.email ?? '';
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = widget.currentLocale ?? const Locale('en');
    final currentLocale = Localizations.localeOf(context);
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final secondaryText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: TextStyle(color: primaryText),
        ),
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              SettingsPageCard(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryText,
                            ),
                          ),
                          if (_email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsSectionCard(
                title: localizations.account,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  SettingsNavTile(
                    icon: Icons.person_outline,
                    label: localizations.profile,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder:
                              (context) => ProfilePage(
                                fullName: _fullName,
                                phoneNumber: _phone,
                              ),
                        ),
                      );
                    },
                  ),
                  SettingsNavTile(
                    icon: Icons.lock_outline,
                    label: localizations.changePassword,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () => _goToChangePassword(activeLocale),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsSectionCard(
                title: localizations.application,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  SettingsNavTile(
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
                      return SettingsNavTile(
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
              const SizedBox(height: 8),
              SettingsSectionCard(
                title: localizations.other,
                titleColor: secondaryText,
                backgroundColor: cardColor,
                borderColor: borderColor,
                children: [
                  SettingsNavTile(
                    icon: Icons.info_outline,
                    label: localizations.aboutApp,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AboutAppPage(),
                        ),
                      );
                    },
                  ),
                  SettingsNavTile(
                    icon: Icons.privacy_tip_outlined,
                    label: localizations.privacyPolicy,
                    iconColor: primaryText,
                    textColor: primaryText,
                    trailingColor: secondaryText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _goToChangePassword(Locale currentLocale) {
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
  }

  Future<void> _logout() async {
    await AccountActions.showLogoutConfirmAndExecute(context);
  }
}
