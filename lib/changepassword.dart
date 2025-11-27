import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';

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

  // Password requirements checkers
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

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // إعادة المصادقة بالمستخدم الحالي
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // تغيير كلمة المرور
      await user.updatePassword(newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.passwordChangedSuccess),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = localizations.currentPasswordIncorrect;
          break;
        case 'weak-password':
          errorMessage = localizations.passwordWeak;
          break;
        case 'requires-recent-login':
          errorMessage = localizations.requiresRecentLogin;
          break;
        default:
          errorMessage = localizations.passwordChangeError;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.passwordChangeError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
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
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.changePassword,
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          if (widget.onLanguageChanged != null)
            LanguageSwitcher(
              currentLocale: currentLocale,
              onLanguageChanged: widget.onLanguageChanged!,
            ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: localizations.currentPassword,
                  obscureText: _obscureCurrentPassword,
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
                const SizedBox(height: 10),
                // Password requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.passwordRequirements,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordRequirement(
                        localizations.characters816,
                        hasMinLength,
                      ),
                      _buildPasswordRequirement(
                        localizations.uppercaseLetter,
                        hasUppercase,
                      ),
                      _buildPasswordRequirement(
                        localizations.lowercaseLetter,
                        hasLowercase,
                      ),
                      _buildPasswordRequirement(
                        localizations.oneNumber,
                        hasNumber,
                      ),
                      _buildPasswordRequirement(
                        localizations.specialCharacter,
                        hasSpecialChar,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: localizations.confirmPassword,
                  obscureText: _obscureConfirmPassword,
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
                const SizedBox(height: 10),
                // Password match indicator
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
                const SizedBox(height: 30),
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.backgroundWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        localizations.changePassword,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.textDark, fontSize: 18),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.backgroundWhite,
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primary,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
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
              color: isValid ? AppColors.textDark : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
