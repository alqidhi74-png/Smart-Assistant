import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';
import 'changepassword.dart';
import 'login.dart';
=======
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b

class AdminHome extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const AdminHome({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
<<<<<<< HEAD
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _fullName = 'Admin';

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
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _logout() async {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.logout),
            content: Text(localizations.logoutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.logout),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) => Login(
                  onLanguageChanged: widget.onLanguageChanged,
                  currentLocale: widget.currentLocale,
                ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      key: _scaffoldKey,
=======
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
      appBar: AppBar(
        title: Text(
          localizations.adminHome,
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
<<<<<<< HEAD
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textOnDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
        actions: [
          if (widget.onLanguageChanged != null)
            LanguageSwitcher(
              currentLocale: currentLocale,
              onLanguageChanged: widget.onLanguageChanged!,
            ),
        ],
      ),
<<<<<<< HEAD
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: AppColors.textOnDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fullName,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.primary),
              title: Text(localizations.changePassword),
              onTap: () {
                Navigator.pop(context);
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(localizations.logout),
              onTap: _logout,
            ),
          ],
        ),
      ),
=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.welcomeAdmin,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.adminHomePage,
              style: const TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======

>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
