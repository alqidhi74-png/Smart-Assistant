import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static Future<Locale> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    return Locale(languageCode);
  }

  static Future<void> setLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  static Future<void> toggleLanguage() async {
    final current = await getCurrentLanguage();
    final newLocale = current.languageCode == 'ar' ? english : arabic;
    await setLanguage(newLocale);
  }
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Translations
  String get login => locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Login';
  String get register => locale.languageCode == 'ar' ? 'التسجيل' : 'Register';
  String get forgotPassword =>
      locale.languageCode == 'ar' ? 'نسيت كلمة المرور' : 'Forgot Password';
  String get homePage =>
      locale.languageCode == 'ar' ? 'الصفحة الرئيسية' : 'Home Page';
  String get adminHome =>
      locale.languageCode == 'ar' ? 'لوحة التحكم' : 'Admin Home';

  // Login page
  String get email =>
      locale.languageCode == 'ar' ? 'البريد الإلكتروني' : 'Email';
  String get password =>
      locale.languageCode == 'ar' ? 'كلمة المرور' : 'Password';
  String get forgotPasswordLink =>
      locale.languageCode == 'ar'
          ? 'نسيت كلمة المرور؟ اضغط هنا'
          : 'Forgot your password? Reset it here';
  String get dontHaveAccount =>
      locale.languageCode == 'ar'
          ? 'ليس لديك حساب؟ سجل هنا.'
          : "Don't have an account? Register here.";

  // Register page
  String get fullName =>
      locale.languageCode == 'ar' ? 'الاسم الكامل' : 'Full Name';
  String get phoneNumber =>
      locale.languageCode == 'ar' ? 'رقم الهاتف' : 'Phone Number';
  String get confirmPassword =>
      locale.languageCode == 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get alreadyHaveAccount =>
      locale.languageCode == 'ar'
          ? 'لديك حساب بالفعل؟ سجل دخول هنا.'
          : 'Already have an account? Login here.';

  // Forgot password page
  String get resetYourPassword =>
      locale.languageCode == 'ar'
          ? 'إعادة تعيين كلمة المرور'
          : 'Reset your password';
  String get enterEmailForReset =>
      locale.languageCode == 'ar'
          ? 'أدخل بريدك الإلكتروني لاستلام رابط إعادة التعيين'
          : 'Enter your email to receive a password reset link';
  String get sendResetEmail =>
      locale.languageCode == 'ar'
          ? 'إرسال رابط إعادة التعيين'
          : 'Send Reset Email';
  String get passwordResetSent =>
      locale.languageCode == 'ar'
          ? 'تم إرسال رابط إعادة تعيين كلمة المرور! تحقق من بريدك.'
          : 'Password reset email sent! Check your inbox.';

  // Validation messages
  String get emailRequired =>
      locale.languageCode == 'ar'
          ? 'البريد الإلكتروني مطلوب'
          : 'Email is required';
  String get validEmail =>
      locale.languageCode == 'ar'
          ? 'يرجى إدخال بريد إلكتروني صحيح'
          : 'Please enter a valid email address';
  String get passwordRequired =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور مطلوبة'
          : 'Password is required';
  String get fullNameRequired =>
      locale.languageCode == 'ar'
          ? 'الاسم الكامل مطلوب'
          : 'Full name is required';
  String get fullNameLettersOnly =>
      locale.languageCode == 'ar'
          ? 'الاسم يجب أن يحتوي على حروف فقط'
          : 'Full name must contain only letters';
  String get phoneRequired =>
      locale.languageCode == 'ar'
          ? 'رقم الهاتف مطلوب'
          : 'Phone number is required';
  String get phoneOmani =>
      locale.languageCode == 'ar'
          ? 'رقم الهاتف يجب أن يكون عماني (يبدأ بـ 9 أو 7) و 8 أرقام'
          : 'Phone number must be Omani (starts with 9 or 7) and 8 digits';
  String get confirmPasswordRequired =>
      locale.languageCode == 'ar'
          ? 'يرجى تأكيد كلمة المرور'
          : 'Please confirm your password';
  String get passwordsNotMatch =>
      locale.languageCode == 'ar'
          ? 'كلمات المرور غير متطابقة'
          : 'Passwords do not match';

  // Password requirements
  String get passwordRequirements =>
      locale.languageCode == 'ar'
          ? 'متطلبات كلمة المرور:'
          : 'Password Requirements:';
  String get characters816 =>
      locale.languageCode == 'ar' ? '8-16 حرف' : '8-16 characters';
  String get uppercaseLetter =>
      locale.languageCode == 'ar'
          ? 'حرف كبير واحد على الأقل'
          : 'At least one uppercase letter';
  String get lowercaseLetter =>
      locale.languageCode == 'ar'
          ? 'حرف صغير واحد على الأقل'
          : 'At least one lowercase letter';
  String get oneNumber =>
      locale.languageCode == 'ar'
          ? 'رقم واحد على الأقل'
          : 'At least one number';
  String get specialCharacter =>
      locale.languageCode == 'ar'
          ? 'رمز خاص واحد على الأقل'
          : 'At least one special character';
  String get passwordsMatch =>
      locale.languageCode == 'ar' ? 'كلمات المرور متطابقة' : 'Passwords match';
  String get passwordsDoNotMatch =>
      locale.languageCode == 'ar'
          ? 'كلمات المرور غير متطابقة'
          : 'Passwords do not match';

  // Password validation
  String get passwordLength =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور يجب أن تكون بين 8 و 16 حرف'
          : 'Password must be between 8 and 16 characters';
  String get passwordUppercase =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل'
          : 'Password must contain at least one uppercase letter';
  String get passwordLowercase =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل'
          : 'Password must contain at least one lowercase letter';
  String get passwordNumber =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل'
          : 'Password must contain at least one number';
  String get passwordSpecial =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل'
          : 'Password must contain at least one special character';

  // Home pages
  String get welcome => locale.languageCode == 'ar' ? 'مرحباً' : 'Welcome';
  String get welcomeAdmin =>
      locale.languageCode == 'ar' ? 'مرحباً، المدير!' : 'Welcome, Admin!';
  String get userHomePage =>
      locale.languageCode == 'ar'
          ? 'هذه هي صفحة المستخدم الرئيسية'
          : 'This is the user home page';
  String get adminHomePage =>
      locale.languageCode == 'ar'
          ? 'هذه هي صفحة المدير الرئيسية'
          : 'This is the admin home page';

  // Login error messages
  String get invalidEmailOrPassword =>
      locale.languageCode == 'ar'
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة'
          : 'Invalid email or password';
  String get userNotFound =>
      locale.languageCode == 'ar'
          ? 'البريد الإلكتروني غير مسجل'
          : 'Email address not found';
  String get wrongPassword =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور غير صحيحة'
          : 'Incorrect password';
  String get userDisabled =>
      locale.languageCode == 'ar'
          ? 'تم تعطيل هذا الحساب'
          : 'This account has been disabled';
  String get tooManyRequests =>
      locale.languageCode == 'ar'
          ? 'محاولات كثيرة جداً. يرجى المحاولة لاحقاً'
          : 'Too many attempts. Please try again later';
  String get networkError =>
      locale.languageCode == 'ar'
          ? 'خطأ في الاتصال بالإنترنت. يرجى التحقق من الاتصال'
          : 'Network error. Please check your connection';
  String get loginError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى'
          : 'An error occurred during login. Please try again';
  String get userDataNotFound =>
      locale.languageCode == 'ar'
          ? 'بيانات المستخدم غير موجودة'
          : 'User data not found';

  // Change password
  String get changePassword =>
      locale.languageCode == 'ar' ? 'تغيير كلمة المرور' : 'Change Password';
  String get currentPassword =>
      locale.languageCode == 'ar' ? 'كلمة المرور الحالية' : 'Current Password';
  String get newPassword =>
      locale.languageCode == 'ar' ? 'كلمة المرور الجديدة' : 'New Password';
  String get currentPasswordRequired =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور الحالية مطلوبة'
          : 'Current password is required';
  String get currentPasswordIncorrect =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور الحالية غير صحيحة'
          : 'Current password is incorrect';
  String get passwordChangedSuccess =>
      locale.languageCode == 'ar'
          ? 'تم تغيير كلمة المرور بنجاح'
          : 'Password changed successfully';
  String get passwordChangeError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء تغيير كلمة المرور'
          : 'An error occurred while changing password';
  String get passwordWeak =>
      locale.languageCode == 'ar'
          ? 'كلمة المرور ضعيفة جداً'
          : 'Password is too weak';
  String get requiresRecentLogin =>
      locale.languageCode == 'ar'
          ? 'يرجى تسجيل الدخول مرة أخرى'
          : 'Please login again';

  // Logout
  String get logout => locale.languageCode == 'ar' ? 'تسجيل الخروج' : 'Logout';
  String get logoutConfirm =>
      locale.languageCode == 'ar'
          ? 'هل أنت متأكد من تسجيل الخروج؟'
          : 'Are you sure you want to logout?';
  String get cancel => locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
