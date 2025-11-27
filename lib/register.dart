import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'login.dart';
import 'data/database.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';

class Registration extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const Registration({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  RegistrationState createState() => RegistrationState();
}

class RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;

  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();

<<<<<<< HEAD
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
  String admin = 'N';

  // Password requirements checkers
  bool get hasMinLength =>
      passwordController.text.length >= 8 &&
      passwordController.text.length <= 16;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordController.text);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(passwordController.text);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(passwordController.text);
  bool get hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordController.text);
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
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.register,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
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
                const SizedBox(height: 40),
                _buildTextField(
                  controller: fullNameController,
                  label: localizations.fullName,
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.fullNameRequired;
                    }
                    // Check if contains only letters and spaces
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return localizations.fullNameLettersOnly;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  label: localizations.email,
                  icon: Icons.email,
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
                const SizedBox(height: 20),
                _buildTextField(
                  controller: phoneController,
                  label: localizations.phoneNumber,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.phoneRequired;
                    }
                    // Check if starts with 9 or 7 and length is exactly 8
                    if (!RegExp(r'^[79]\d{7}$').hasMatch(value)) {
                      return localizations.phoneOmani;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
<<<<<<< HEAD
                _buildPasswordField(
                  controller: passwordController,
                  label: localizations.password,
                  obscureText: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
=======
                _buildTextField(
                  controller: passwordController,
                  label: localizations.password,
                  icon: Icons.lock,
                  obscureText: true,
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.passwordRequired;
                    }
                    if (value.length < 8 || value.length > 16) {
                      return localizations.passwordLength;
                    }
                    // Check for uppercase letter
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return localizations.passwordUppercase;
                    }
                    // Check for lowercase letter
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return localizations.passwordLowercase;
                    }
                    // Check for number
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return localizations.passwordNumber;
                    }
                    // Check for special character
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
<<<<<<< HEAD
                _buildPasswordField(
                  controller: confirmpasswordController,
                  label: localizations.confirmPassword,
                  obscureText: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
=======
                _buildTextField(
                  controller: confirmpasswordController,
                  label: localizations.confirmPassword,
                  icon: Icons.lock,
                  obscureText: true,
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.confirmPasswordRequired;
                    }
                    if (value != passwordController.text) {
                      return localizations.passwordsNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Password match indicator
                if (confirmpasswordController.text.isNotEmpty)
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
                ElevatedButton(
                  onPressed: onPressed,
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
                    localizations.register,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => Login(
                              onLanguageChanged: widget.onLanguageChanged,
                              currentLocale: currentLocale,
                            ),
                      ),
                    );
                  },
                  child: Text(
                    localizations.alreadyHaveAccount,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textDark, fontSize: 18),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.backgroundWhite,
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
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

<<<<<<< HEAD
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

=======
>>>>>>> 60535d7e2aef5273a14aba9d7411eb2ffd88927b
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

  Future<void> onPressed() async {
    if (_formKey.currentState!.validate()) {
      final currentLocale = widget.currentLocale ?? const Locale('en');
      await Database().registerUser(
        fullNameController.text,
        emailController.text,
        phoneController.text,
        passwordController.text,
        admin,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => Login(
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: currentLocale,
              ),
        ),
      );
    }
  }
}
