import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
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

class HomePage extends StatefulWidget {
  final String fullName;
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const HomePage({
    super.key,
    required this.fullName,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
<<<<<<< HEAD
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
<<<<<<< HEAD
      key: _scaffoldKey,
=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
      appBar: AppBar(
        title: Text(
          localizations.homePage,
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
                    Icons.person,
                    size: 48,
                    color: AppColors.textOnDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.fullName,
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
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${localizations.welcome}, ${widget.fullName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.userHomePage,
              style: const TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
