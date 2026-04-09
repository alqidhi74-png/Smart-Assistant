import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface;
    final textColor =
        isDark
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2C) : Theme.of(context).colorScheme.outline;
    return Drawer(
      child: Container(
        color: bgColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: bgColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 44, color: textColor),
                  const SizedBox(height: 8),
                  Text(
                    adminName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: dividerColor,
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
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
            ),
            _buildTile(
              context,
              icon: Icons.category,
              label: localizations.categoryPage,
              onTap: onCategory,
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
            ),
            _buildTile(
              context,
              icon: Icons.group,
              label: localizations.userDetailsPage,
              onTap: onUserDetails,
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
            ),
            _buildTile(
              context,
              icon: Icons.feedback_outlined,
              label: localizations.feedback,
              onTap: onFeedback,
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
            ),
            _buildTile(
              context,
              icon: Icons.settings_outlined,
              label: localizations.settings,
              onTap: onSettings,
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
            ),
            _buildTile(
              context,
              icon: Icons.logout,
              label: localizations.logout,
              onTap: onLogout,
              iconColor: textColor,
              textColor: textColor,
              dividerColor: dividerColor,
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
    required Color iconColor,
    required Color textColor,
    required Color dividerColor,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onTap?.call();
          },
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}
