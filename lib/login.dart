import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_language_sheet.dart';
import 'forgetpassword.dart';
import 'register.dart';
import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'utils/app_snackbar.dart';
import 'utils/firebase_auth_user_message.dart';
import 'services/multi_account_service.dart';

class Login extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const Login({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _animateIn = false;
  AnimationController? _bgController;

  AnimationController get _animatedBgController {
    return _bgController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  bool _isBlockedValue(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'y' || s == 'yes';
  }

  @override
  void initState() {
    super.initState();
    _animatedBgController;
    _loadRemembered();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _bgController?.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    final rememberedEmail = prefs.getString('remember_email') ?? '';
    final rememberedPassword = prefs.getString('remember_password') ?? '';
    if (remember) {
      emailController.text = rememberedEmail;
      passwordController.text = rememberedPassword;
    }
    setState(() {
      _rememberMe = remember;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = Localizations.localeOf(context);
    final backgroundGradient =
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
            );
    final cardColor =
        isDark ? const Color(0xFF121E33) : AppColors.backgroundWhite;
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
          Container(decoration: BoxDecoration(gradient: backgroundGradient)),
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
                                color: cardColor,
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
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                              Text(
                                localizations.login,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                localizations.welcome,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 22),
                              _buildTextField(
                                context: context,
                                controller: emailController,
                                label: localizations.email,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
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
                              const SizedBox(height: 14),
                              _buildPasswordField(
                                context: context,
                                controller: passwordController,
                                label: localizations.password,
                                obscureText: _obscurePassword,
                                onToggle: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.passwordRequired;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _rememberMe,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                  title: Text(
                                    AppLocalizations.of(context)?.rememberMe ??
                                        'Remember me',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: titleColor,
                                    ),
                                  ),
                                  secondary: const SizedBox.shrink(),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ForgotPasswordScreen(
                                              onLanguageChanged:
                                                  widget.onLanguageChanged,
                                              currentLocale: currentLocale,
                                            ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    localizations.forgotPasswordLink,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: onPressed,
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
                                  localizations.login,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => Registration(
                                            onLanguageChanged:
                                                widget.onLanguageChanged,
                                            currentLocale: currentLocale,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  localizations.dontHaveAccount,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF12233F) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2D4463) : AppColors.borderLight;
    final labelColor = isDark ? const Color(0xFFB8C7DA) : AppColors.textGray;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textDark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF12233F) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2D4463) : AppColors.borderLight;
    final labelColor = isDark ? const Color(0xFFB8C7DA) : AppColors.textGray;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textDark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primary,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> onPressed() async {
    if (_formKey.currentState!.validate()) {
      try {
        final emailTrim = emailController.text.trim();
        final localizationsEarly =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));

        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailTrim,
              password: passwordController.text.trim(),
            );
        final signedUser = credential.user;
        if (signedUser == null) {
          if (!mounted) return;
          AppSnackBar.showError(
            context,
            localizationsEarly.invalidEmailOrPassword,
          );
          return;
        }
        final uid = signedUser.uid;

        if (!mounted) return;

        final dbRef = FirebaseDatabase.instance.ref();
        final snapshot = await dbRef.child('users/$uid').get();

        if (!mounted) return;

        final localizations =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));
        if (snapshot.exists) {
          final raw = snapshot.value;
          if (raw is! Map) {
            if (!mounted) return;
            AppSnackBar.showError(context, localizations.userDataNotFound);
            return;
          }
          final data = Map<dynamic, dynamic>.from(raw);
          final isBlocked = _isBlockedValue(data['blocked']);

          if (isBlocked) {
            await FirebaseAuth.instance.signOut();
            await MultiAccountService.removeStoredAccount(uid);
            if (!mounted) return;
            final supportMessage =
                '${localizations.accountBlockedMessage}\n\n${localizations.contactUs}: ${localizations.supportPhoneValue}\n${localizations.email}: ${localizations.supportEmailValue}';
            showDialog<void>(
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
            return;
          }

          final name = data['fullName']?.toString() ?? '';
          await MultiAccountService.recordSuccessfulLogin(
            uid: uid,
            email: emailTrim,
            password: passwordController.text.trim(),
            displayName: name,
          );

          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setBool('remember_me', true);
            await prefs.setString(
              'remember_email',
              emailController.text.trim(),
            );
            await prefs.setString(
              'remember_password',
              passwordController.text,
            );
          } else {
            await prefs.setBool('remember_me', false);
            await prefs.remove('remember_email');
            await prefs.remove('remember_password');
          }

          if (!mounted) return;

          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          if (!mounted) return;
          final localizations =
              AppLocalizations.of(context) ??
              AppLocalizations(const Locale('en'));
          AppSnackBar.showError(context, localizations.userDataNotFound);
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        final localizations =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));
        AppSnackBar.showError(
          context,
          firebaseAuthUserMessage(
            e,
            localizations,
            context: FirebaseAuthMessageContext.login,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final localizations =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));
        AppSnackBar.showError(context, localizations.invalidEmailOrPassword);
      }
    }
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
