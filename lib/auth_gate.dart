import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'admin/adminhome.dart';
import 'constants/language.dart';
import 'landing_page.dart';
import 'services/multi_account_service.dart';
import 'user/navbar.dart';
import 'utils/app_error_reporter.dart';
import 'utils/loading_overlay.dart';

/// Matches how [Database] stores `admin` ('Y' / 'N') and tolerates bool / casing.
bool _isAdminFromRtdb(Map<dynamic, dynamic> data) {
  final v = data['admin'];
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toUpperCase();
  return s == 'Y' || s == 'YES';
}

bool _isBlockedFromRtdb(Map<dynamic, dynamic> data) {
  final v = data['blocked'];
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'y' || s == 'yes';
}

class AuthGate extends StatelessWidget {
  final void Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const AuthGate({
    super.key,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MultiAccountService.accountSessionVersion,
      builder: (context, _, __) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final authUser = FirebaseAuth.instance.currentUser;
            final streamUser = snapshot.data;
            // Prefer live session; stream can lag one frame after account switch.
            final User? user = authUser ?? streamUser;

            final waiting =
                snapshot.connectionState == ConnectionState.waiting;
            if (user == null && waiting && authUser == null && streamUser == null) {
              return const Scaffold(body: IosStyleLoading());
            }
            if (user == null) {
              return LandingPage(
                onLanguageChanged: onLanguageChanged,
                currentLocale: currentLocale,
              );
            }
            return _SignedInRouter(
              key: ValueKey<String>(user.uid),
              uid: user.uid,
              onLanguageChanged: onLanguageChanged,
              currentLocale: currentLocale,
            );
          },
        );
      },
    );
  }
}

class _SignedInRouter extends StatefulWidget {
  final String uid;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const _SignedInRouter({
    super.key,
    required this.uid,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<_SignedInRouter> createState() => _SignedInRouterState();
}

class _SignedInRouterState extends State<_SignedInRouter> {
  bool _profileTimedOut = false;
  int _retryToken = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) setState(() => _profileTimedOut = true);
    });
  }

  @override
  void didUpdateWidget(covariant _SignedInRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _profileTimedOut = false;
      _retryToken++;
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted) setState(() => _profileTimedOut = true);
      });
    }
  }

  Widget _connectionIssue(AppLocalizations loc) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                loc.profileLoadFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _profileTimedOut = false;
                    _retryToken++;
                  });
                  Future.delayed(const Duration(seconds: 12), () {
                    if (mounted) setState(() => _profileTimedOut = true);
                  });
                },
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    return StreamBuilder<DatabaseEvent>(
      key: ValueKey<String>('${widget.uid}_$_retryToken'),
      stream: FirebaseDatabase.instance
          .ref('users/${widget.uid}')
          .onValue
          .timeout(
            const Duration(seconds: 15),
            onTimeout: (EventSink<DatabaseEvent> sink) {
              sink.close();
            },
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          AppErrorReporter.debug(
            'AuthGate users/${widget.uid} stream',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _connectionIssue(loc);
        }
        if (!snapshot.hasData) {
          if (_profileTimedOut) {
            return _connectionIssue(loc);
          }
          return const Scaffold(body: IosStyleLoading());
        }
        _profileTimedOut = false;
        final snap = snapshot.data!.snapshot;
        if (!snap.exists) {
          return _MissingProfileGate(
            onLanguageChanged: widget.onLanguageChanged,
            currentLocale: widget.currentLocale,
          );
        }
        final raw = snap.value;
        if (raw is! Map) {
          return _MissingProfileGate(
            onLanguageChanged: widget.onLanguageChanged,
            currentLocale: widget.currentLocale,
          );
        }
        final data = Map<dynamic, dynamic>.from(raw);
        final fullName = data['fullName']?.toString() ?? '';
        final isBlocked = _isBlockedFromRtdb(data);

        if (isBlocked) {
          return _BlockedAccountGate(
            onLanguageChanged: widget.onLanguageChanged,
            currentLocale: widget.currentLocale,
          );
        }

        final isAdmin = _isAdminFromRtdb(data);

        if (isAdmin) {
          return AdminHome(
            key: ValueKey<String>('admin_${widget.uid}'),
            onLanguageChanged: widget.onLanguageChanged,
            currentLocale: widget.currentLocale,
          );
        }
        return UserNavBar(
          key: UserNavBar.navKey,
          uid: widget.uid,
          fullName: fullName,
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: widget.currentLocale,
        );
      },
    );
  }
}

class _MissingProfileGate extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const _MissingProfileGate({
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<_MissingProfileGate> createState() => _MissingProfileGateState();
}

class _MissingProfileGateState extends State<_MissingProfileGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const Scaffold(body: IosStyleLoading());
    }
    return LandingPage(
      onLanguageChanged: widget.onLanguageChanged,
      currentLocale: widget.currentLocale,
    );
  }
}

class _BlockedAccountGate extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const _BlockedAccountGate({
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<_BlockedAccountGate> createState() => _BlockedAccountGateState();
}

class _BlockedAccountGateState extends State<_BlockedAccountGate> {
  bool _signedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showThenSignOut());
  }

  Future<void> _showThenSignOut() async {
    if (!mounted) return;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.accountBlockedTitle),
            content: Text(
              '${localizations.accountBlockedMessage}\n\n'
              '${localizations.contactUs}: ${localizations.supportPhoneValue}\n'
              '${localizations.email}: ${localizations.supportEmailValue}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.ok),
              ),
            ],
          ),
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseAuth.instance.signOut();
    if (uid != null && uid.isNotEmpty) {
      await MultiAccountService.removeStoredAccount(uid);
    }
    if (mounted) setState(() => _signedOut = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedOut) {
      return const Scaffold(body: IosStyleLoading());
    }
    return LandingPage(
      onLanguageChanged: widget.onLanguageChanged,
      currentLocale: widget.currentLocale,
    );
  }
}
