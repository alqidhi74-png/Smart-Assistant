import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'data/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/firebase_auth_user_message.dart';
import 'login.dart';
import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'services/multi_account_service.dart';
import 'utils/app_snackbar.dart';
import 'constants/language.dart';

class Registration extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const Registration({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  RegistrationState createState() => RegistrationState();
}

class RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String admin = 'N';

  bool get hasMinLength =>
      passwordController.text.length >= 8 &&
      passwordController.text.length <= 16;

  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordController.text);

  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(passwordController.text);

  bool get hasNumber => RegExp(r'[0-9]').hasMatch(passwordController.text);

  bool get hasSpecialChar =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(passwordController.text);

  bool get passwordsMatch =>
      passwordController.text == confirmpasswordController.text &&
      confirmpasswordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() => setState(() {}));
    confirmpasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');
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
                padding: EdgeInsets.fromLTRB(
                  AppLayout.pagePaddingH,
                  24,
                  AppLayout.pagePaddingH,
                  20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
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
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  localizations.register,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  localizations.createAccount,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 22),
                                _buildTextField(
                                  context: context,
                                  controller: fullNameController,
                                  label: localizations.fullName,
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations.fullNameRequired;
                                    }
                                    if (value.length > 30) {
                                      return localizations.fullNameMaxLength;
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z\s]+$',
                                    ).hasMatch(value)) {
                                      return localizations.fullNameLettersOnly;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
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
                                _buildTextField(
                                  context: context,
                                  controller: phoneController,
                                  label: localizations.phoneNumber,
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations.phoneRequired;
                                    }
                                    if (!RegExp(
                                      r'^[79]\d{7}$',
                                    ).hasMatch(value)) {
                                      return localizations.phoneOmani;
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
                                    if (value.length < 8 || value.length > 16) {
                                      return localizations.passwordLength;
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                      return localizations.passwordUppercase;
                                    }
                                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                                      return localizations.passwordLowercase;
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return localizations.passwordNumber;
                                    }
                                    if (!RegExp(
                                      r'[!@#\$%^&*(),.?":{}|<>]',
                                    ).hasMatch(value)) {
                                      return localizations.passwordSpecial;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? const Color(0xFF12233F)
                                            : AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizations.passwordRequirements,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildPasswordRequirement(
                                        context,
                                        localizations.characters816,
                                        hasMinLength,
                                      ),
                                      _buildPasswordRequirement(
                                        context,
                                        localizations.uppercaseLetter,
                                        hasUppercase,
                                      ),
                                      _buildPasswordRequirement(
                                        context,
                                        localizations.lowercaseLetter,
                                        hasLowercase,
                                      ),
                                      _buildPasswordRequirement(
                                        context,
                                        localizations.oneNumber,
                                        hasNumber,
                                      ),
                                      _buildPasswordRequirement(
                                        context,
                                        localizations.specialCharacter,
                                        hasSpecialChar,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildPasswordField(
                                  context: context,
                                  controller: confirmpasswordController,
                                  label: localizations.confirmPassword,
                                  obscureText: _obscureConfirmPassword,
                                  onToggle: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations
                                          .confirmPasswordRequired;
                                    }
                                    if (value != passwordController.text) {
                                      return localizations.passwordsNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                                if (confirmpasswordController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          passwordsMatch
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color:
                                              passwordsMatch
                                                  ? const Color(0xFF2E7D32)
                                                  : theme.colorScheme.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          passwordsMatch
                                              ? localizations.passwordsMatch
                                              : localizations
                                                  .passwordsDoNotMatch,
                                          style: TextStyle(
                                            color:
                                                passwordsMatch
                                                    ? const Color(0xFF2E7D32)
                                                    : theme.colorScheme.error,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 18),
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
                                    localizations.register,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => Login(
                                              onLanguageChanged:
                                                  widget.onLanguageChanged,
                                              currentLocale: currentLocale,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    localizations.alreadyHaveAccount,
                                    style: TextStyle(
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

  Widget _buildPasswordRequirement(
    BuildContext context,
    String text,
    bool isValid,
  ) {
    final theme = Theme.of(context);
    const green = Color(0xFF2E7D32);
    final red = theme.colorScheme.error;
    final iconColor = isValid ? green : red;
    final textColor = isValid ? green : red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> onPressed() async {
    if (_formKey.currentState!.validate()) {
      final localizations =
          AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

      try {
        await Database().registerUser(
          fullNameController.text.trim(),
          emailController.text.trim(),
          phoneController.text.trim(),
          passwordController.text.trim(),
          admin,
        );
        if (!mounted) return;

        final signedIn = FirebaseAuth.instance.currentUser;
        if (signedIn != null) {
          final savedOk = await MultiAccountService.recordSuccessfulLogin(
            uid: signedIn.uid,
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            displayName: fullNameController.text.trim(),
          );
          if (!savedOk && mounted) {
            AppSnackBar.showInfo(
              context,
              localizations.accountNotSavedDeviceLimit,
            );
          }
        }
        if (!mounted) return;

        AppSnackBar.showSuccess(
          context,
          localizations.registerSuccess,
          duration: const Duration(seconds: 2),
        );

        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          firebaseAuthUserMessage(
            e,
            localizations,
            context: FirebaseAuthMessageContext.register,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        AppSnackBar.showError(context, localizations.registerError);
      }
    }
  }
}
