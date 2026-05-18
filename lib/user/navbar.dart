import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/bill_store.dart';
import '../services/multi_account_service.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import 'chatbot.dart';
import 'homepage.dart';
import 'mybills.dart';
import 'setting.dart';

class UserNavBar extends StatefulWidget {
  static final GlobalKey<_UserNavBarState> navKey = GlobalKey<_UserNavBarState>();

  static void switchTab(int index, {String? chatbotMessage}) {
    navKey.currentState?._updateIndex(index, chatbotMessage: chatbotMessage);
  }

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
  String? _pendingChatbotMessage;
  late String _fullName;

  @override
  void initState() {
    super.initState();
    _fullName = widget.fullName;
    BillStore.instance.ensureListening();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MultiAccountService.syncCredentialIfRememberedMatches();
    });
  }

  void _updateIndex(int index, {String? chatbotMessage}) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _pendingChatbotMessage = chatbotMessage;
    });
  }

  @override
  void didUpdateWidget(UserNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _currentIndex = 0;
      _blockedDialogShown = false;
      _fullName = widget.fullName;
      BillStore.instance.resetForUserSwitch();
      BillStore.instance.ensureListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = Localizations.localeOf(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DatabaseEvent>(
      stream: user != null ? FirebaseDatabase.instance.ref('users/${user.uid}').onValue : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
          final data = snapshot.data!.snapshot.value as Map;
          final name = data['fullName']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            _fullName = name;
          }
          if (_isBlockedValue(data['blocked'])) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleBlockedUser(context, localizations));
          }
        }

        return Scaffold(
          body: IndexedStack(
            key: ValueKey<String>('user_stack_${widget.uid}'),
            index: _currentIndex,
            children: [
              HomePage(
                fullName: _fullName,
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
                initialMessage: _pendingChatbotMessage,
              ),
              SettingPage(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
                fullName: _fullName,
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            onTap: (index) => _updateIndex(index),
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: localizations.home),
              BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: localizations.myBills),
              BottomNavigationBarItem(icon: const Icon(Icons.smart_toy_outlined), label: localizations.aiChatbot),
              BottomNavigationBarItem(icon: const Icon(Icons.settings), label: localizations.settings),
            ],
          ),
        );
      },
    );
  }

  bool _isBlockedValue(dynamic value) {
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  Future<void> _handleBlockedUser(BuildContext context, AppLocalizations loc) async {
    if (_blockedDialogShown) return;
    _blockedDialogShown = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.accountBlockedTitle),
        content: Text(loc.accountBlockedMessage),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.ok))],
      ),
    );
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }
}
