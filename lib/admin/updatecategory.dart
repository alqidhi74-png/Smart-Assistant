import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../core/utils.dart';
import 'adminhome.dart';
import 'sidebar.dart';
import 'category.dart';
import 'userdetails.dart';
import 'profile.dart';
import 'feedback.dart';

class AdminUpdateCategoryPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminUpdateCategoryPage({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<AdminUpdateCategoryPage> createState() =>
      _AdminUpdateCategoryPageState();
}

class _AdminUpdateCategoryPageState extends State<AdminUpdateCategoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final activeLocale = widget.currentLocale ?? const Locale('en');
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

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
        onSettings:
            () => _openPage(
              AdminProfilePage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: activeLocale,
              ),
            ),
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: Text(
          localizations.updateCategory,
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textOnDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: const [],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildPlaceholder(
        icon: Icons.update,
        title: localizations.updateCategory,
        subtitle: localizations.editCategoriesHint,
      ),
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final secondaryTextColor =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textGray;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: secondaryTextColor)),
        ],
      ),
    );
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

  Future<void> _logout() async {
    await AccountActions.showLogoutChoiceAndExecute(context);
  }
}
