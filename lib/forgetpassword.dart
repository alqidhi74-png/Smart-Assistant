import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/utils.dart';

import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'constants/language.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const ForgotPasswordScreen({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<ForgotPasswordScreen> createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  Future<void> resetPassword() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      loading = true;
    });

    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      AppSnackBar.showSuccess(context, localizations.passwordResetSent);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      if (!mounted) return;
      AppSnackBar.showError(context, _authMessage(e, localizations));
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        localizations.passwordResetGenericError,
      );
    }
  }

  String _authMessage(FirebaseAuthException e, AppLocalizations loc) {
    switch (e.code) {
      case 'invalid-email':
        return loc.validEmail;
      case 'user-not-found':
        return loc.passwordResetNoUserForEmail;
      case 'too-many-requests':
        return loc.tooManyRequests;
      case 'network-request-failed':
        return loc.networkError;
      default:
        return loc.passwordResetGenericError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = theme.brightness == Brightness.dark;
    final cardBorder =
        isDark ? const Color(0xFF223552) : const Color(0xFFE6EBF2);
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final subtitleColor =
        isDark ? const Color(0xFF9FB1C7) : AppColors.textSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A1628), Color(0xFF0B1E39)],
                  )
                  : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3F6FB), Color(0xFFFFFFFF)],
                  ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.pagePaddingH,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.formMaxWidth,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF121E33)
                                  : AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isDark
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                  color: AppColors.primary,
                                  tooltip: localizations.cancel,
                                ),
                              ),
                              Text(
                                localizations.forgotPassword,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                localizations.enterEmailForReset,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppColors.textOnDark
                                          : AppColors.textDark,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      isDark
                                          ? const Color(0xFF12233F)
                                          : AppColors.backgroundWhite,
                                  labelText: localizations.email,
                                  labelStyle: TextStyle(
                                    color:
                                        isDark
                                            ? const Color(0xFFB8C7DA)
                                            : AppColors.textGray,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: AppColors.primary,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.error,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.error,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.emailRequired;
                                  }
                                  if (!EmailValidator.validate(value)) {
                                    return localizations.validEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              loading
                                  ? const IosStyleLoading()
                                  : ElevatedButton(
                                    onPressed: resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      localizations.sendResetEmail,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
