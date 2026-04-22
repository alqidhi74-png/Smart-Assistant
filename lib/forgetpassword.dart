import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'utils/app_language_sheet.dart';

import 'utils/loading_overlay.dart';
import 'package:smart_assistant/utils/app_snackbar.dart';

import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'utils/firebase_auth_user_message.dart';

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

class ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;
  bool _animateIn = false;
  AnimationController? _bgController;

  AnimationController get _animatedBgController {
    return _bgController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void initState() {
    super.initState();
    _animatedBgController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _bgController?.dispose();
    emailController.dispose();
    super.dispose();
  }

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
      AppSnackBar.showError(
        context,
        firebaseAuthUserMessage(
          e,
          localizations,
          context: FirebaseAuthMessageContext.forgotPassword,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = Localizations.localeOf(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBorder =
        isDark ? const Color(0xFF223552) : const Color(0xFFE6EBF2);
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final subtitleColor =
        isDark ? const Color(0xFF9FB1C7) : AppColors.textSecondary;
    final accentBorder =
        isDark
            ? AppColors.secondary.withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.32);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient:
                  isDark
                      ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF081427), Color(0xFF0F325C)],
                      )
                      : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.secondary.withValues(alpha: 0.14),
                          Colors.white,
                        ],
                      ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            top: _animateIn ? -40 : -80,
            right: _animateIn ? -20 : -60,
            child: AnimatedBuilder(
              animation: _animatedBgController,
              builder: (context, child) {
                final t = _animatedBgController.value * 2 * math.pi;
                return Transform.translate(
                  offset: Offset(math.sin(t) * 14, math.cos(t * 1.2) * 10),
                  child: Transform.scale(
                    scale: 1 + math.sin(t) * 0.12,
                    child: child,
                  ),
                );
              },
              child: _AuthOrb(
                size: 180,
                color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.2),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            bottom: _animateIn ? -60 : -100,
            left: _animateIn ? -30 : -70,
            child: AnimatedBuilder(
              animation: _animatedBgController,
              builder: (context, child) {
                final t = _animatedBgController.value * 2 * math.pi;
                return Transform.translate(
                  offset: Offset(math.cos(t * 0.9) * 12, math.sin(t) * 14),
                  child: Transform.scale(
                    scale: 1 + math.cos(t) * 0.1,
                    child: child,
                  ),
                );
              },
              child: _AuthOrb(
                size: 220,
                color:
                    AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.22),
              ),
            ),
          ),
          SafeArea(
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
                        child: AnimatedSlide(
                          offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _animateIn ? 1 : 0,
                            duration: const Duration(milliseconds: 850),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF121E33)
                                        : AppColors.backgroundWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: accentBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isDark
                                            ? Colors.black.withValues(alpha: 0.45)
                                            : Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: isDark ? 0.16 : 0.12,
                                    ),
                                    blurRadius: 26,
                                    spreadRadius: 1,
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
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 40,
            right: currentLocale.languageCode == 'ar' ? null : 20,
            left: currentLocale.languageCode == 'ar' ? 20 : null,
            child: InkWell(
              onTap:
                  () => showAppLanguageSheet(
                    context,
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : theme.primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : theme.primaryColor)
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language,
                      size: 16,
                      color: isDark ? Colors.white : theme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentLocale.languageCode == 'ar' ? 'العربية' : 'English',
                      style: TextStyle(
                        color: isDark ? Colors.white : theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
