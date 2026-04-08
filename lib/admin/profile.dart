import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../changepassword.dart';
import '../core/utils.dart';
import 'adminhome.dart';
import '../providers/theme_provider.dart';
import '../user/about_app.dart';
import '../user/privacy_policy.dart';
import 'sidebar.dart';
import 'category.dart';
import 'userdetails.dart';
import 'feedback.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F3F3);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final secondaryTextColor =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminSidebar(
        adminName: 'Admin',
        onHome: _goHome,
        onCategory:
            () => _openPage(
              AdminCategoryPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onUserDetails:
            () => _openPage(
              AdminUserDetailsPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onFeedback:
            () => _openPage(
              AdminFeedbackPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onSettings: () => Navigator.pop(context),
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: Text(localizations.settings, style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: localizations.accountsTitle,
            onPressed: _openAccountMenu,
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: cardColor,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: ListView(
        padding: AppLayout.pagePadding,
        children: [
          _buildProfileCard(cardColor, textColor, secondaryTextColor),
          const SizedBox(height: 12),
          _buildSectionTitle(localizations.account, textColor),
          _buildSectionCard(
            cardColor: cardColor,
            children: [
              _buildTile(
                icon: Icons.person,
                label: localizations.profile,
                onTap: _showEditProfileDialog,
                textColor: textColor,
              ),
              _buildDivider(dividerColor),
              _buildTile(
                icon: Icons.lock_outline,
                label: localizations.changePassword,
                onTap: () => _goToChangePassword(activeLocale),
                textColor: textColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionTitle(localizations.application, textColor),
          _buildSectionCard(
            cardColor: cardColor,
            children: [
              _buildLanguageRow(textColor, secondaryTextColor),
              _buildDivider(dividerColor),
              _buildDarkModeRow(textColor),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionTitle(localizations.other, textColor),
          _buildSectionCard(
            cardColor: cardColor,
            children: [
              _buildTile(
                icon: Icons.info_outline,
                label: localizations.aboutApp,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AboutAppPage(),
                    ),
                  );
                },
                textColor: textColor,
              ),
              _buildDivider(dividerColor),
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                label: localizations.privacyPolicy,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
                textColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.pagePaddingH + 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : AppColors.backgroundLight,
            child: Icon(Icons.person, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildSectionCard({
    required List<Widget> children,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(height: 1, color: dividerColor);
  }

  Widget _buildLanguageRow(Color textColor, Color secondaryTextColor) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final effective = normalizeSupportedLocale(Localizations.localeOf(context));
    return ListTile(
      leading: Icon(Icons.public, color: textColor),
      title: Text(
        localizations.language,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageDisplayName(effective),
            style: TextStyle(color: secondaryTextColor),
          ),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, color: secondaryTextColor),
        ],
      ),
      onTap:
          () => showAppLanguageSheet(
            context,
            onLanguageChanged: widget.onLanguageChanged,
          ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  Widget _buildDarkModeRow(Color textColor) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return SwitchListTile(
      title: Text(
        localizations.darkMode,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      secondary: Icon(Icons.dark_mode, color: textColor),
      value: themeNotifier.isDarkMode,
      onChanged: (value) => themeNotifier.setThemeMode(value),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phone);
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFECECEC);
    final textColor = isDark ? Colors.white : AppColors.textDark;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder:
          (context) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: EdgeInsets.all(AppLayout.pagePaddingH + 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.editProfile,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: nameController,
                      icon: Icons.person,
                      hint: localizations.fullName,
                      textColor: textColor,
                      fillColor:
                          isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFD1D1D1),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: phoneController,
                      icon: Icons.phone,
                      hint: localizations.phoneNumber,
                      textColor: textColor,
                      fillColor:
                          isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFD1D1D1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildDialogButton(
                          label: localizations.cancel,
                          color:
                              isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFDCDCDC),
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        _buildDialogButton(
                          label: localizations.save,
                          color: const Color(0xFF7BE27B),
                          onTap: () async {
                            Navigator.pop(context);
                            await _saveProfile(
                              nameController.text,
                              phoneController.text,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color textColor,
    required Color fillColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.pagePaddingH),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 12, color: textColor),
        decoration: InputDecoration(
          icon: Icon(icon, size: 16, color: textColor),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.pagePaddingH,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(String fullName, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseDatabase.instance.ref().child('users/${user.uid}').update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
    });
    if (mounted) {
      setState(() {
        _fullName = fullName.trim().isEmpty ? _fullName : fullName.trim();
        _phone = phone.trim();
      });
    }
  }

  void _goHome() {
    final currentLocale = widget.currentLocale ?? const Locale('en');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminHome(
              onLanguageChanged: widget.onLanguageChanged,
              currentLocale: currentLocale,
            ),
      ),
      (route) => false,
    );
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
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

  Future<void> _openAccountMenu() async {
    await AccountActions.showAccountSwitcherSheet(
      context: context,
      onLanguageChanged: widget.onLanguageChanged,
      currentLocale: widget.currentLocale ?? const Locale('en'),
    );
  }

  Future<void> _logout() async {
    await AccountActions.showLogoutChoiceAndExecute(context);
  }
}
