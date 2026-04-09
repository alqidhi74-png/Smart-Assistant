import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/app_layout.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import '../utils/app_snackbar.dart';
import '../utils/firebase_auth_user_message.dart';
import '../utils/loading_overlay.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const ChangePasswordScreen({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  bool get hasMinLength =>
      newPasswordController.text.length >= 8 &&
      newPasswordController.text.length <= 16;
  bool get hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(newPasswordController.text);
  bool get hasLowercase =>
      RegExp(r'[a-z]').hasMatch(newPasswordController.text);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(newPasswordController.text);
  bool get hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPasswordController.text);
  bool get passwordsMatch =>
      newPasswordController.text == confirmPasswordController.text &&
      confirmPasswordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(() => setState(() {}));
    confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    setState(() {
      _loading = true;
    });
    if (mounted) LoadingOverlay.show(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPasswordController.text);

      if (mounted) {
        AppSnackBar.showSuccess(context, localizations.passwordChangedSuccess);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          firebaseAuthUserMessage(
            e,
            localizations,
            context: FirebaseAuthMessageContext.changePassword,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, localizations.passwordChangeError);
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide();
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final secondaryTextColor =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final fieldFillColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD3D3D3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.changePassword,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
        actions: const [],
      ),
      body: Container(
        color: backgroundColor,
        child: Padding(
          padding: AppLayout.pagePadding,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: localizations.currentPassword,
                  obscureText: _obscureCurrentPassword,
                  fillColor: fieldFillColor,
                  labelColor: secondaryTextColor,
                  textColor: textColor,
                  iconColor: textColor,
                  onToggle: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.currentPasswordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: localizations.newPassword,
                  obscureText: _obscureNewPassword,
                  fillColor: fieldFillColor,
                  labelColor: secondaryTextColor,
                  textColor: textColor,
                  iconColor: textColor,
                  onToggle: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
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
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      return localizations.passwordSpecial;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(AppLayout.pagePaddingH + 6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.passwordRequirements,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordRequirement(
                        localizations.characters816,
                        hasMinLength,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      _buildPasswordRequirement(
                        localizations.uppercaseLetter,
                        hasUppercase,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      _buildPasswordRequirement(
                        localizations.lowercaseLetter,
                        hasLowercase,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      _buildPasswordRequirement(
                        localizations.oneNumber,
                        hasNumber,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      _buildPasswordRequirement(
                        localizations.specialCharacter,
                        hasSpecialChar,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: localizations.confirmPassword,
                  obscureText: _obscureConfirmPassword,
                  fillColor: fieldFillColor,
                  labelColor: secondaryTextColor,
                  textColor: textColor,
                  iconColor: textColor,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.confirmPasswordRequired;
                    }
                    if (value != newPasswordController.text) {
                      return localizations.passwordsNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (confirmPasswordController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          passwordsMatch ? Icons.check_circle : Icons.cancel,
                          color: passwordsMatch ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          passwordsMatch
                              ? localizations.passwordsMatch
                              : localizations.passwordsDoNotMatch,
                          style: TextStyle(
                            color: passwordsMatch ? Colors.green : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                _loading
                    ? const IosStyleLoading()
                    : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F6EBC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        localizations.changePassword,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required Color fillColor,
    required Color labelColor,
    required Color textColor,
    required Color iconColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        prefixIcon: Icon(Icons.lock, color: iconColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: iconColor,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fillColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordRequirement(
    String text,
    bool isValid, {
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? textColor : secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
