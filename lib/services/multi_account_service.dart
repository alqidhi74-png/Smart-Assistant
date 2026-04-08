import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bill_store.dart';

/// One switch at a time so [signOut]/[signInWithEmailAndPassword] cannot interleave.
final class _AccountSwitchSerial {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() fn) async {
    final prev = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      await prev.catchError((_) {});
      return await fn();
    } finally {
      if (!done.isCompleted) {
        done.complete();
      }
    }
  }
}

final _accountSwitchSerial = _AccountSwitchSerial();

/// Thrown when switching accounts but no password is stored for that account.
class MissingStoredCredentialsException implements Exception {
  final String uid;
  MissingStoredCredentialsException(this.uid);
}

/// Thrown when the target account is marked as blocked in RTDB.
class BlockedAccountException implements Exception {
  final String uid;
  BlockedAccountException(this.uid);
}

/// Stores multiple account identities (prefs) and credentials (secure storage).
/// Switches Firebase session with one sign-in; avoids background polling.
abstract final class MultiAccountService {
  /// Bumped after every successful account switch so [AuthGate] rebuilds even if
  /// [authStateChanges] lags behind [FirebaseAuth.instance.currentUser].
  static final ValueNotifier<int> accountSessionVersion = ValueNotifier<int>(0);

  static void _notifySessionChanged() {
    accountSessionVersion.value++;
  }

  /// Max number of distinct accounts stored on this device for quick switching.
  static const int maxSavedAccounts = 2;

  static const _prefsKey = 'multi_accounts_v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _pwdKey(String uid) => 'acc_pwd_$uid';

  static List<SavedAccount> _dedupeAndCap(List<SavedAccount> list) {
    final seen = <String>{};
    final out = <SavedAccount>[];
    for (final a in list) {
      if (a.uid.isEmpty) continue;
      if (seen.add(a.uid)) out.add(a);
      if (out.length >= maxSavedAccounts) break;
    }
    return out;
  }

  static Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list =
          decoded
              .map(
                (e) =>
                    SavedAccount.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      final normalized = _dedupeAndCap(list);
      if (normalized.length != list.length) {
        await _writeAccounts(normalized);
        final kept = normalized.map((a) => a.uid).toSet();
        for (final a in list) {
          if (a.uid.isNotEmpty && !kept.contains(a.uid)) {
            await _storage.delete(key: _pwdKey(a.uid));
          }
        }
      }
      return normalized;
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
    await prefs.setString(
      _prefsKey,
      jsonEncode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  /// Returns `true` if this account was written to the saved list and secure
  /// storage. Returns `false` when the device already has [maxSavedAccounts]
  /// distinct accounts and [uid] is not one of them (login may still proceed).
  static Future<bool> recordSuccessfulLogin({
    required String uid,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final list = await getSavedAccounts();
    final idx = list.indexWhere((a) => a.uid == uid);
    final entry = SavedAccount(
      uid: uid,
      email: email,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : email,
    );
    if (idx >= 0) {
      list[idx] = entry;
      await _writeAccounts(list);
      await _storage.write(key: _pwdKey(uid), value: password);
      return true;
    }
    if (list.length >= maxSavedAccounts) {
      return false;
    }
    list.add(entry);
    await _writeAccounts(list);
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

  /// Save password for this account and complete switch (sign in as that user).
  static Future<void> savePasswordAndSwitch({
    required String uid,
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _pwdKey(uid), value: password);
    await switchToAccount(uid);
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

  /// Sign in as [uid] using stored password. Resets [BillStore] listeners.
  static Future<void> switchToAccount(String uid) {
    return _accountSwitchSerial.run(() => _switchToAccountImpl(uid));
  }

  static Future<UserCredential> _signInWithRetry({
    required String email,
    required String password,
  }) async {
    const maxAttempts = 3;
    Object? lastError;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        return await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        lastError = e;
        final retry =
            e.code == 'network-request-failed' ||
            (e.message?.toLowerCase().contains('network') ?? false);
        if (!retry || i == maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
      }
    }
    throw lastError ?? StateError('signIn failed');
  }

  static Future<void> _switchToAccountImpl(String uid) async {
    final list = await getSavedAccounts();
    SavedAccount? acc;
    for (final a in list) {
      if (a.uid == uid) {
        acc = a;
        break;
      }
    }
    if (acc == null) {
      throw StateError('Account not found');
    }
    var pwd = await readPassword(uid);
    if (pwd == null || pwd.isEmpty) {
      pwd = await recoverPasswordFromRememberPrefs(acc.email);
      if (pwd != null && pwd.isNotEmpty) {
        await _storage.write(key: _pwdKey(uid), value: pwd);
      }
    }
    if (pwd == null || pwd.isEmpty) {
      throw MissingStoredCredentialsException(uid);
    }
    BillStore.instance.resetForUserSwitch();
    await FirebaseAuth.instance.signOut();
    final cred = await _signInWithRetry(email: acc.email, password: pwd);
    final signed = cred.user;
    if (signed == null || signed.uid != uid) {
      await FirebaseAuth.instance.signOut();
      throw StateError('Account switch did not complete');
    }
    final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
    final raw = userSnap.value;
    if (raw is Map) {
      final blockedRaw = raw['blocked'];
      final blocked =
          blockedRaw == true ||
          blockedRaw?.toString().trim().toLowerCase() == 'true' ||
          blockedRaw?.toString().trim().toLowerCase() == '1' ||
          blockedRaw?.toString().trim().toLowerCase() == 'y' ||
          blockedRaw?.toString().trim().toLowerCase() == 'yes';
      if (blocked) {
        await FirebaseAuth.instance.signOut();
        await removeStoredAccount(uid);
        throw BlockedAccountException(uid);
      }
    }
    await BillStore.instance.ensureListening();
    _notifySessionChanged();
  }

  /// Quick login from landing (no Firebase user yet).
  static Future<void> signInWithStoredAccount(String uid) async {
    await switchToAccount(uid);
  }

  /// Log out current user and remove only this account from device storage.
  static Future<void> logoutCurrentRemoveFromDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    BillStore.instance.resetForUserSwitch();
    await FirebaseAuth.instance.signOut();
    await removeStoredAccount(uid);
    _notifySessionChanged();
  }

  /// Sign out and remove every saved account from this device.
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
