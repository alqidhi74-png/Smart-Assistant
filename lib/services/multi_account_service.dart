import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bill_store.dart';

/// Persists credentials for at most **one** account on this device (remember-me / quick metadata).
abstract final class MultiAccountService {
  /// Bumped after logout so [AuthGate] rebuilds even if auth stream lags.
  static final ValueNotifier<int> accountSessionVersion = ValueNotifier<int>(0);

  static void _notifySessionChanged() {
    accountSessionVersion.value++;
  }

  static const _prefsKey = 'multi_accounts_v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _pwdKey(String uid) => 'acc_pwd_$uid';

  /// Returns zero or one saved account (legacy lists with multiple entries are trimmed on read).
  static Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      if (decoded.isEmpty) return [];
      final first = SavedAccount.fromJson(
        Map<String, dynamic>.from(decoded.first as Map),
      );
      if (decoded.length > 1) {
        for (var i = 1; i < decoded.length; i++) {
          final m = Map<String, dynamic>.from(decoded[i] as Map);
          final uid = m['uid']?.toString() ?? '';
          if (uid.isNotEmpty) {
            await _storage.delete(key: _pwdKey(uid));
          }
        }
        await _writeAccounts([first]);
      }
      return [first];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    if (accounts.isEmpty) {
      await prefs.remove(_prefsKey);
      return;
    }
    final one = accounts.take(1).toList();
    await prefs.setString(
      _prefsKey,
      jsonEncode(one.map((e) => e.toJson()).toList()),
    );
  }

  /// Stores this user as the only saved account on the device and saves password in secure storage.
  static Future<bool> recordSuccessfulLogin({
    required String uid,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final existing = await getSavedAccounts();
    for (final a in existing) {
      if (a.uid != uid) {
        await _storage.delete(key: _pwdKey(a.uid));
      }
    }
    final entry = SavedAccount(
      uid: uid,
      email: email,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : email,
    );
    await _writeAccounts([entry]);
    await _storage.write(key: _pwdKey(uid), value: password);
    return true;
  }

  static Future<void> updateDisplayName(String uid, String displayName) async {
    final list = await getSavedAccounts();
    final idx = list.indexWhere((a) => a.uid == uid);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      displayName:
          displayName.trim().isNotEmpty
              ? displayName.trim()
              : list[idx].displayName,
    );
    await _writeAccounts(list);
  }

  static Future<String?> readPassword(String uid) async {
    return _storage.read(key: _pwdKey(uid));
  }

  /// If "Remember me" holds the same email as [email], copy password into secure storage.
  static Future<String?> recoverPasswordFromRememberPrefs(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') != true) return null;
    final rememberEmail =
        (prefs.getString('remember_email') ?? '').trim().toLowerCase();
    if (rememberEmail != trimmed) return null;
    final pwd = prefs.getString('remember_password');
    if (pwd == null || pwd.isEmpty) return null;
    return pwd;
  }

  /// When session is restored (no fresh login), sync secure password from "Remember me" if it matches.
  static Future<void> syncCredentialIfRememberedMatches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final email = user.email;
    if (email == null || email.isEmpty) return;
    final existing = await readPassword(user.uid);
    if (existing != null && existing.isNotEmpty) return;
    final recovered = await recoverPasswordFromRememberPrefs(email);
    if (recovered != null && recovered.isNotEmpty) {
      await _storage.write(key: _pwdKey(user.uid), value: recovered);
    }
  }

  /// Remove one account from device (prefs + password). Does not sign out.
  static Future<void> removeStoredAccount(String uid) async {
    final list = await getSavedAccounts();
    list.removeWhere((a) => a.uid == uid);
    await _writeAccounts(list);
    await _storage.delete(key: _pwdKey(uid));
  }

  static Future<void> clearAllStoredAccounts() async {
    final list = await getSavedAccounts();
    for (final a in list) {
      await _storage.delete(key: _pwdKey(a.uid));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Sign out and clear saved session data for this device.
  static Future<void> logoutCurrentRemoveFromDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    BillStore.instance.resetForUserSwitch();
    await FirebaseAuth.instance.signOut();
    await removeStoredAccount(uid);
    _notifySessionChanged();
  }

  /// Same as [logoutCurrentRemoveFromDevice] with a single account on device.
  static Future<void> logoutAllRemoveFromDevice() async {
    BillStore.instance.resetForUserSwitch();
    await FirebaseAuth.instance.signOut();
    await clearAllStoredAccounts();
    _notifySessionChanged();
  }
}

@immutable
class SavedAccount {
  final String uid;
  final String email;
  final String displayName;

  const SavedAccount({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> m) {
    return SavedAccount(
      uid: m['uid']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      displayName: m['displayName']?.toString() ?? m['email']?.toString() ?? '',
    );
  }

  SavedAccount copyWith({String? displayName}) {
    return SavedAccount(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
    );
  }
}
