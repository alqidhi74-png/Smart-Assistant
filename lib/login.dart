import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminhome.dart';
import 'forgetpassword.dart';
import 'homepage.dart';
import 'register.dart';
import 'constants/colors.dart';
import 'constants/language.dart';
import 'widgets/language_switcher.dart';

class Login extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const Login({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  // Don't call FirebaseAuth.instance at construction time to keep widgets
  // testable without initializing Firebase. Access the instance lazily
  // inside `onPressed` when needed.
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final currentLocale = widget.currentLocale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.login,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
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
          child: Center(
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 40),

                  // Email
                  _buildTextField(
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

                  const SizedBox(height: 20),

                  // Password
                  _buildPasswordField(
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

                  const SizedBox(height: 8),

                  // ***** Remember Me (الآن تحت الباسورد) *****
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _rememberMe,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                    title: Text(
                      AppLocalizations.of(context)?.rememberMe ?? 'Remember me',
                      style: const TextStyle(fontSize: 14),
                    ),
                    secondary: const SizedBox.shrink(),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 10),

                  // Forgot password
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ForgotPasswordScreen(
                                onLanguageChanged: widget.onLanguageChanged,
                                currentLocale: currentLocale,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      localizations.forgotPasswordLink,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login button
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
                      localizations.login,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Registration(
                                onLanguageChanged: widget.onLanguageChanged,
                                currentLocale: currentLocale,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      localizations.dontHaveAccount,
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

  Future<void> onPressed() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
        final uid = credential.user!.uid;

        if (!mounted) return;

        final dbRef = FirebaseDatabase.instance.ref();
        final snapshot = await dbRef.child('users/$uid').get();

        if (!mounted) return;

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final fullName = data['fullName'] as String;
          final admin = data['admin'] as String;
          final currentLocale = widget.currentLocale ?? const Locale('en');

          // Save remember me
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setBool('remember_me', true);
            await prefs.setString(
              'remember_email',
              emailController.text.trim(),
            );
            await prefs.setString('remember_password', passwordController.text);
          } else {
            await prefs.setBool('remember_me', false);
            await prefs.remove('remember_email');
            await prefs.remove('remember_password');
          }

          if (!mounted) return;

          if (admin == 'Y') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AdminHome(
                      onLanguageChanged: widget.onLanguageChanged,
                      currentLocale: currentLocale,
                    ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      fullName: fullName,
                      onLanguageChanged: widget.onLanguageChanged,
                      currentLocale: currentLocale,
                    ),
              ),
            );
          }
        } else {
          if (!mounted) return;
          final localizations =
              AppLocalizations.of(context) ??
              AppLocalizations(const Locale('en'));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.userDataNotFound),
              backgroundColor: AppColors.error,
            ),
          );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final localizations =
            AppLocalizations.of(context) ??
            AppLocalizations(const Locale('en'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.invalidEmailOrPassword),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
