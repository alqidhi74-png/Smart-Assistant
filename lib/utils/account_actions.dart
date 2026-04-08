import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/language.dart';
import '../login.dart';
import '../services/multi_account_service.dart';
import 'app_error_reporter.dart';
import 'app_snackbar.dart';
import 'loading_overlay.dart';

/// Shared account switcher (user + admin) and multi-account logout sheet.
abstract final class AccountActions {
  /// Clears pushed routes (e.g. upload / detail) so the new session shows root UI.
  static void _popNavigationToRoot(BuildContext context) {
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  /// Switch to [account] using stored password, or prompt once if missing.
  static Future<void> performAccountSwitch(
    BuildContext context,
    SavedAccount account,
    AppLocalizations loc,
  ) async {
    LoadingOverlay.show(context);
    try {
      await MultiAccountService.switchToAccount(account.uid);
      LoadingOverlay.hide();
      _popNavigationToRoot(context);
      return;
    } on MissingStoredCredentialsException catch (_) {
      LoadingOverlay.hide();
      if (!context.mounted) return;
      final pwd = await _showPasswordForAccountDialog(context, account, loc);
      if (pwd == null || pwd.isEmpty) return;
      if (!context.mounted) return;
      LoadingOverlay.show(context);
      try {
        await MultiAccountService.savePasswordAndSwitch(
          uid: account.uid,
          email: account.email,
          password: pwd,
        );
        if (context.mounted) {
          _popNavigationToRoot(context);
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackBar.showError(context, loc.accountSwitchError);
        }
      } finally {
        LoadingOverlay.hide();
      }
    } on BlockedAccountException catch (_) {
      LoadingOverlay.hide();
      if (!context.mounted) return;
      final supportMessage =
          '${loc.accountBlockedMessage}\n\n${loc.contactUs}: ${loc.supportPhoneValue}\n${loc.email}: ${loc.supportEmailValue}';
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(loc.accountBlockedTitle),
              content: Text(supportMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.ok),
                ),
              ],
            ),
      );
    } catch (e, st) {
      AppErrorReporter.debug('performAccountSwitch', e, st);
      LoadingOverlay.hide();
      if (context.mounted) {
        AppSnackBar.showError(context, loc.accountSwitchError);
      }
    }
  }

  static Future<String?> _showPasswordForAccountDialog(
    BuildContext context,
    SavedAccount account,
    AppLocalizations loc,
  ) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _AccountPasswordDialog(account: account, loc: loc);
      },
    );
  }

  static Future<void> showLogoutChoiceAndExecute(BuildContext context) async {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  localizations.logoutChooseTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(localizations.logoutFromCurrentDevice),
                subtitle: Text(
                  localizations.logoutFromCurrentDeviceSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'current'),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text(localizations.logoutFromAllAccounts),
                subtitle: Text(
                  localizations.logoutFromAllAccountsSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'all'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(localizations.cancel),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;
    if (choice == 'current') {
      await MultiAccountService.logoutCurrentRemoveFromDevice();
    } else {
      await MultiAccountService.logoutAllRemoveFromDevice();
    }
  }

  static Future<void> showAccountSwitcherSheet({
    required BuildContext context,
    required void Function(Locale)? onLanguageChanged,
    required Locale currentLocale,
  }) async {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final saved = await MultiAccountService.getSavedAccounts();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    loc.accountsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...saved.map((a) {
                  final isCurrent = a.uid == user.uid;
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.check_circle : Icons.person_outline,
                      color:
                          isCurrent
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                    title: Text(a.displayName),
                    subtitle: Text(a.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrent)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: AppColors.error,
                            tooltip: loc.removeSavedAccountAction,
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) {
                                  return AlertDialog(
                                    title: Text(loc.removeSavedAccountTitle),
                                    content: Text(
                                      loc.removeSavedAccountMessage(a.email),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.pop(dialogCtx, false),
                                        child: Text(loc.cancel),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.pop(dialogCtx, true),
                                        child: Text(loc.delete),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (ok != true || !context.mounted) return;
                              Navigator.pop(ctx);
                              await MultiAccountService.removeStoredAccount(
                                a.uid,
                              );
                              if (context.mounted) {
                                AppSnackBar.showSuccess(
                                  context,
                                  loc.accountRemovedFromDevice,
                                );
                              }
                            },
                          ),
                        if (isCurrent)
                          Chip(
                            label: Text(loc.currentAccountBadge),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    onTap:
                        isCurrent
                            ? null
                            : () {
                              Navigator.pop(ctx);
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                if (!context.mounted) return;
                                await performAccountSwitch(context, a, loc);
                              });
                            },
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  enabled: saved.length < MultiAccountService.maxSavedAccounts,
                  leading: Icon(
                    Icons.add_circle_outline,
                    color:
                        saved.length < MultiAccountService.maxSavedAccounts
                            ? null
                            : Theme.of(ctx).disabledColor,
                  ),
                  title: Text(loc.addAccount),
                  subtitle:
                      saved.length >= MultiAccountService.maxSavedAccounts
                          ? Text(
                            loc.accountLimitReachedShort,
                            style: const TextStyle(fontSize: 12),
                          )
                          : null,
                  onTap:
                      saved.length >= MultiAccountService.maxSavedAccounts
                          ? null
                          : () {
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push<void>(
                                MaterialPageRoute<void>(
                                  builder:
                                      (c) => Login(
                                        onLanguageChanged: onLanguageChanged,
                                        currentLocale: currentLocale,
                                        addAccountMode: true,
                                      ),
                                ),
                              );
                            });
                          },
                ),
                SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Owns [TextEditingController] for the account-switch password dialog so the
/// controller lifecycle cannot conflict with route disposal (avoids framework errors).
class _AccountPasswordDialog extends StatefulWidget {
  const _AccountPasswordDialog({required this.account, required this.loc});

  final SavedAccount account;
  final AppLocalizations loc;

  @override
  State<_AccountPasswordDialog> createState() => _AccountPasswordDialogState();
}

class _AccountPasswordDialogState extends State<_AccountPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onVar = theme.colorScheme.onSurfaceVariant;

    return AlertDialog(
      title: Text(widget.loc.accountSwitchEnterPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.account.email, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              widget.loc.accountSwitchEnterPasswordHint,
              style: TextStyle(fontSize: 12, color: onVar),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.loc.password,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.loc.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.loc.accountSwitchConfirm),
        ),
      ],
    );
  }
}
