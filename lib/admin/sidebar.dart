import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/language.dart';

class AdminSidebar extends StatelessWidget {
  final String adminName;
  final VoidCallback? onHome;
  final VoidCallback? onCategory;
  final VoidCallback? onUserDetails;
  final VoidCallback? onFeedback;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const AdminSidebar({
    super.key,
    this.adminName = 'Admin',
    this.onHome,
    this.onCategory,
    this.onUserDetails,
    this.onFeedback,
    this.onSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    return Drawer(
      child: Container(
        color: const Color(0xFFE0E0E0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 44),
                  const SizedBox(height: 8),
                  Text(
                    adminName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    color: AppColors.textDark,
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ),
            ),
            _buildTile(
              context,
              icon: Icons.home,
              label: localizations.homePage,
              onTap: onHome,
            ),
            _buildTile(
              context,
              icon: Icons.category,
              label: localizations.categoryPage,
              onTap: onCategory,
            ),
            _buildTile(
              context,
              icon: Icons.group,
              label: localizations.userDetailsPage,
              onTap: onUserDetails,
            ),
            _buildTile(
              context,
              icon: Icons.feedback_outlined,
              label: localizations.feedback,
              onTap: onFeedback,
            ),
            _buildTile(
              context,
              icon: Icons.settings_outlined,
              label: localizations.settings,
              onTap: onSettings,
            ),
            _buildTile(
              context,
              icon: Icons.logout,
              label: localizations.logout,
              onTap: onLogout,
              iconColor: AppColors.textDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color iconColor = AppColors.textDark,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onTap?.call();
          },
        ),
        const Divider(height: 1, color: AppColors.textDark),
      ],
    );
  }
}
