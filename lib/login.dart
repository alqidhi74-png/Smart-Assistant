import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgetpassword.dart';
import 'register.dart';
import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'core/utils.dart';
import 'services/multi_account_service.dart';

class Login extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;
  final bool addAccountMode;

  const Login({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
    this.addAccountMode = false,
  });

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool _isBlockedValue(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'y' || s == 'yes';
  }

  @override
  void initState() {
    super.initState();
    _loadRemembered();
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
    final currentLocale = widget.currentLocale ?? const Locale('en');
    final backgroundGradient =
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
            );
    final cardColor =
        isDark ? const Color(0xFF121E33) : AppColors.backgroundWhite;
    final cardBorder =
        isDark ? const Color(0xFF223552) : const Color(0xFFE6EBF2);
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final subtitleColor =
        isDark ? const Color(0xFF9FB1C7) : AppColors.textSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
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
                          color: cardColor,
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
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.addAccountMode) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed:
                                        () =>
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop(),
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                              ],
                              Text(
                                widget.addAccountMode
                                    ? localizations.loginAddAccountTitle
                                    : localizations.login,
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
                              if (!widget.addAccountMode)
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
                                    Navigator.of(
                                      context,
                                      rootNavigator: widget.addAccountMode,
                                    ).push(
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
                                  Navigator.of(
                                    context,
                                    rootNavigator: widget.addAccountMode,
                                  ).push(
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
              );
            },
          ),
        ),
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
        if (widget.addAccountMode) {
          final saved = await MultiAccountService.getSavedAccounts();
          final alreadySaved = saved.any(
            (a) => a.email.toLowerCase() == emailTrim.toLowerCase(),
          );
          if (!alreadySaved &&
              saved.length >= MultiAccountService.maxSavedAccounts) {
            if (!mounted) return;
            AppSnackBar.showError(
              context,
              localizationsEarly.accountLimitReached,
            );
            return;
          }
        }

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
          final savedOk = await MultiAccountService.recordSuccessfulLogin(
            uid: uid,
            email: emailTrim,
            password: passwordController.text.trim(),
            displayName: name,
          );
          if (!savedOk) {
            if (widget.addAccountMode) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              AppSnackBar.showError(context, localizations.accountLimitReached);
              return;
            }
            if (!mounted) return;
            AppSnackBar.showInfo(
              context,
              localizations.accountNotSavedDeviceLimit,
            );
          }

          final prefs = await SharedPreferences.getInstance();
          if (!widget.addAccountMode) {
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
          }

          if (!mounted) return;

          if (widget.addAccountMode) {
            // Pop after this frame so AuthGate / Navigator are not updating the
            // route table in the same build phase (avoids duplicate Navigator GlobalKey).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pop(true);
            });
            return;
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          if (!mounted) return;
          final localizations =
              AppLocalizations.of(context) ??
              AppLocalizations(const Locale('en'));
          AppSnackBar.showError(context, localizations.userDataNotFound);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (!mounted) return;
        final localizations =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));

        switch (e.code) {
          case 'user-not-found':
          case 'invalid-credential':
            errorMessage = localizations.invalidEmailOrPassword;
            break;
          case 'wrong-password':
            errorMessage = localizations.invalidEmailOrPassword;
            break;
          case 'invalid-email':
            errorMessage = localizations.invalidEmailOrPassword;
            break;
          case 'user-disabled':
            errorMessage = localizations.userDisabled;
            break;
          case 'too-many-requests':
            errorMessage = localizations.tooManyRequests;
            break;
          case 'network-request-failed':
          case 'network-error':
            errorMessage = localizations.networkError;
            break;
          default:
            errorMessage = localizations.invalidEmailOrPassword;
        }

        AppSnackBar.showError(context, errorMessage);
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
