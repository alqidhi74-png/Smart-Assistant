import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/multi_account_service.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import 'chatbot.dart';
import 'homepage.dart';
import 'mybills.dart';
import 'setting.dart';

class UserNavBar extends StatefulWidget {
  /// Firebase Auth uid — used to reset tab state when switching accounts.
  final String uid;
  final String fullName;
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const UserNavBar({
    super.key,
    required this.uid,
    required this.fullName,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<UserNavBar> createState() => _UserNavBarState();
}

class _UserNavBarState extends State<UserNavBar> {
  int _currentIndex = 0;
  bool _blockedDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MultiAccountService.syncCredentialIfRememberedMatches();
    });
  }

  @override
  void didUpdateWidget(UserNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _currentIndex = 0;
      _blockedDialogShown = false;
    }
  }

  Future<void> _handleBlockedUser(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    if (_blockedDialogShown) return;
    _blockedDialogShown = true;
    final supportMessage =
        '${localizations.accountBlockedMessage}\n\n${localizations.contactUs}: ${localizations.supportPhoneValue}\n${localizations.email}: ${localizations.supportEmailValue}';
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.accountBlockedTitle),
            content: Text(supportMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.ok),
              ),
            ],
          ),
    );
    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseAuth.instance.signOut();
    if (uid != null && uid.isNotEmpty) {
      await MultiAccountService.removeStoredAccount(uid);
    }
  }

  bool _isBlockedValue(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'y' || s == 'yes';
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = Localizations.localeOf(context);
    final user = FirebaseAuth.instance.currentUser;

    Widget buildScaffold(String fullName) {
      final pages = [
        HomePage(
          fullName: fullName,
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: currentLocale,
        ),
        MyBillsPage(
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: currentLocale,
        ),
        ChatbotPage(
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: currentLocale,
        ),
        SettingPage(
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: currentLocale,
          fullName: fullName,
        ),
      ];

      return Scaffold(
        body: IndexedStack(
          key: ValueKey<String>('user_pages_${widget.uid}'),
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: localizations.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long),
              label: localizations.myBills,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.smart_toy_outlined),
              label: localizations.aiChatbot,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: localizations.settings,
            ),
          ],
        ),
      );
    }

    if (user == null) {
      return buildScaffold(widget.fullName);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
      builder: (context, snapshot) {
        String fullName = widget.fullName;
        final data = snapshot.data?.snapshot.value;
        if (data is Map) {
          final name = data['fullName']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            fullName = name;
          }
          final isBlocked = _isBlockedValue(data['blocked']);
          if (isBlocked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleBlockedUser(context, localizations);
            });
          }
        }
        return buildScaffold(fullName);
      },
    );
  }
}
