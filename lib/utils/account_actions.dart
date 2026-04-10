import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/language.dart';
import '../services/multi_account_service.dart';

/// Shared logout confirmation for user and admin flows.
abstract final class AccountActions {
  static Future<void> showLogoutConfirmAndExecute(BuildContext context) async {
    final loc =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.logout),
          content: Text(loc.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(loc.logout),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await MultiAccountService.logoutAllRemoveFromDevice();
  }
}
