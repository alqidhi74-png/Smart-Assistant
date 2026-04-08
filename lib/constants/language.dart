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

  String get login => locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Login';

  String get register => locale.languageCode == 'ar' ? 'التسجيل' : 'Register';
  String get createAccount =>
      locale.languageCode == 'ar' ? 'أنشئ حسابك' : 'Create your account';

  String get forgotPassword =>
      locale.languageCode == 'ar' ? 'نسيت كلمة المرور' : 'Forgot Password';

  String get homePage =>
      locale.languageCode == 'ar' ? 'الصفحة الرئيسية' : 'Home Page';

  String get adminHome =>
      locale.languageCode == 'ar' ? 'لوحة التحكم' : 'Admin Home';

  String get adminPageTitle =>
      locale.languageCode == 'ar' ? 'صفحة الادمن' : 'Admin Page';
  String get overview => locale.languageCode == 'ar' ? 'نظرة عامة' : 'Overview';
  String get dashboard =>
      locale.languageCode == 'ar' ? 'لوحة البيانات' : 'Dashboard';
  String get billsDistribution =>
      locale.languageCode == 'ar' ? 'توزيع الفواتير' : 'Bills Distribution';
  String get usersTrend =>
      locale.languageCode == 'ar' ? 'اتجاه المستخدمين' : 'Users Trend';
  String get billsTrend =>
      locale.languageCode == 'ar' ? 'اتجاه الفواتير' : 'Bills Trend';
  String get monthlyOverview =>
      locale.languageCode == 'ar' ? 'نظرة شهرية' : 'Monthly Overview';
  String get accountBlockedTitle =>
      locale.languageCode == 'ar' ? 'تم حظر الحساب' : 'Account blocked';
  String get accountBlockedMessage =>
      locale.languageCode == 'ar'
          ? 'تم حظر حسابك. يرجى التواصل مع الدعم.'
          : 'Your account has been blocked. Please contact support.';
  String get supportPhoneValue =>
      locale.languageCode == 'ar' ? '91208200' : '91208200';
  String get supportEmailValue =>
      locale.languageCode == 'ar' ? 'Mohammed@gmail.com' : 'Mohammed@gmail.com';
  String get electricityBills =>
      locale.languageCode == 'ar' ? 'فواتير الكهرباء' : 'Electricity Bills';
  String get waterBills =>
      locale.languageCode == 'ar' ? 'فواتير المياه' : 'Water Bills';
  String get totalBills =>
      locale.languageCode == 'ar' ? 'إجمالي الفواتير' : 'Total Bills';
  String get users => locale.languageCode == 'ar' ? 'المستخدمون' : 'Users';

  String get categoryPage =>
      locale.languageCode == 'ar' ? 'صفحة التصنيفات' : 'Category Page';
  String get addNewCategory =>
      locale.languageCode == 'ar' ? 'إضافة تصنيف جديد' : 'Add New Category';
  String get addCategory =>
      locale.languageCode == 'ar' ? 'إضافة تصنيف' : 'Add Category';
  String get updateCategory =>
      locale.languageCode == 'ar' ? 'تحديث التصنيف' : 'Update Category';
  String get deleteCategory =>
      locale.languageCode == 'ar' ? 'حذف التصنيف' : 'Delete Category';
  String get categoryName =>
      locale.languageCode == 'ar' ? 'اسم التصنيف' : 'Category Name';
  String get descriptionOptional =>
      locale.languageCode == 'ar'
          ? 'الوصف (اختياري)'
          : 'Description (Optional)';
  String get categoryColor =>
      locale.languageCode == 'ar' ? 'لون البطاقة' : 'Card color';
  String get categoryIcon =>
      locale.languageCode == 'ar' ? 'الأيقونة' : 'Icon';
  String get editCategoriesHint =>
      locale.languageCode == 'ar'
          ? 'تعديل أو حذف التصنيفات الحالية'
          : 'Edit or remove existing categories here.';
  String get bills => locale.languageCode == 'ar' ? 'فواتير' : 'Bills';
  String get noCategories =>
      locale.languageCode == 'ar'
          ? 'لا توجد تصنيفات بعد'
          : 'No categories yet.';

  String get userDetailsPage =>
      locale.languageCode == 'ar'
          ? 'صفحة بيانات المستخدم'
          : 'User Details Page';
  String get searchForUser =>
      locale.languageCode == 'ar' ? 'ابحث عن مستخدم' : 'Search for user';
  String get downloadAllData =>
      locale.languageCode == 'ar' ? 'تحميل كل البيانات' : 'Download All Data';
  String get allUsers =>
      locale.languageCode == 'ar' ? 'كل المستخدمين' : 'All Users';
  String get viewManageUserAccounts =>
      locale.languageCode == 'ar'
          ? 'عرض وإدارة حسابات المستخدمين'
          : 'View and Manage User Accounts';
  String get active => locale.languageCode == 'ar' ? 'نشط' : 'active';
  String get blocked => locale.languageCode == 'ar' ? 'محظور' : 'blocked';
  String get blockUser =>
      locale.languageCode == 'ar' ? 'حظر المستخدم' : 'Block User';
  String get unblockUser =>
      locale.languageCode == 'ar' ? 'إلغاء الحظر' : 'Unblock User';
  String get block => locale.languageCode == 'ar' ? 'حظر' : 'Block';
  String get unblock => locale.languageCode == 'ar' ? 'إلغاء الحظر' : 'Unblock';
  String get download => locale.languageCode == 'ar' ? 'تحميل' : 'Download';
  String get joined => locale.languageCode == 'ar' ? 'تاريخ التسجيل' : 'Joined';
  String get status => locale.languageCode == 'ar' ? 'الحالة' : 'Status';
  String get admin => locale.languageCode == 'ar' ? 'ادمن' : 'Admin';
  String get makeAdmin =>
      locale.languageCode == 'ar' ? 'تعيين ادمن' : 'Make Admin';
  String get revokeAdmin =>
      locale.languageCode == 'ar' ? 'إلغاء ادمن' : 'Revoke';
  String get adminYes => locale.languageCode == 'ar' ? 'نعم' : 'yes';
  String get adminNo => locale.languageCode == 'ar' ? 'لا' : 'no';

  String get feedback => locale.languageCode == 'ar' ? 'الملاحظات' : 'Feedback';
  String get reviewFeedback =>
      locale.languageCode == 'ar'
          ? 'مراجعة الملاحظات المرسلة من المستخدمين'
          : 'Review feedback submitted by users.';
  String get feedbackPageTitle =>
      locale.languageCode == 'ar' ? 'صفحة الملاحظات' : 'Feedback Page';
  String get feedbackPrompt =>
      locale.languageCode == 'ar'
          ? 'شاركنا رأيك لتحسين الخدمة.'
          : 'Share your feedback to improve the service.';
  String get rateYourExperience =>
      locale.languageCode == 'ar' ? 'قيّم تجربتك' : 'Rate your experience';
  String get feedbackDetails =>
      locale.languageCode == 'ar' ? 'تفاصيل الملاحظة' : 'Feedback details';
  String get feedbackHint =>
      locale.languageCode == 'ar'
          ? 'اكتب ملاحظتك هنا...'
          : 'Write your feedback here...';
  String get sendFeedback =>
      locale.languageCode == 'ar' ? 'إرسال الملاحظة' : 'Send feedback';
  String get feedbackRequired =>
      locale.languageCode == 'ar'
          ? 'يرجى كتابة الملاحظة'
          : 'Please add feedback';
  String get feedbackSent =>
      locale.languageCode == 'ar'
          ? 'تم إرسال الملاحظة بنجاح'
          : 'Feedback sent successfully';
  String get feedbackError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء الإرسال'
          : 'Failed to send feedback';
  String get unsupportedBill =>
      locale.languageCode == 'ar'
          ? 'هذه الفاتورة غير مدعومة (ليست كهرباء أو مياه).'
          : 'This bill is not supported (not electricity or water).';

  /// Shown when OCR text is OK but the bill is not classified as water or electricity.
  String get billOnlyWaterElectricAllowed =>
      locale.languageCode == 'ar'
          ? 'يُقبل فقط فواتير الماء أو الكهرباء. لم يُتعرّف على الفاتورة كأحد النوعين.'
          : 'Only water or electricity bills are accepted. This file was not recognized as water or electricity.';

  String get deleteCategoryCascadeBills =>
      locale.languageCode == 'ar'
          ? 'سيتم أيضاً حذف جميع فواتير هذا النوع المحفوظة لجميع المستخدمين.'
          : 'All saved bills of this type will also be removed for all users.';

  String get categoryAndRelatedBillsRemoved =>
      locale.languageCode == 'ar'
          ? 'تم حذف التصنيف والفواتير المرتبطة به.'
          : 'The category and its related bills were removed.';

  String get categoriesLoadError =>
      locale.languageCode == 'ar'
          ? 'تعذّر تحميل التصنيفات. تحقق من الاتصال وحاول مرة أخرى.'
          : 'Could not load categories. Check your connection and try again.';

  String get noUtilityCategoriesConfigured =>
      locale.languageCode == 'ar'
          ? 'لا يوجد تصنيف كهرباء أو مياه في النظام. تواصل مع المسؤول.'
          : 'No electricity or water category is configured. Contact the administrator.';

  String get billTypeRemovedByAdmin =>
      locale.languageCode == 'ar'
          ? 'هذا النوع غير متاح حالياً؛ قام المسؤول بحذف تصنيفه ولا يمكن رفع فواتيره.'
          : 'This type is not available. The administrator removed its category, so uploads for it are blocked.';
  String get filterByStatus =>
      locale.languageCode == 'ar' ? 'تصفية حسب الحالة' : 'Filter by status';
  String get allFeedback =>
      locale.languageCode == 'ar' ? 'كل الملاحظات' : 'All feedback';
  String get userFeedbackSubtitle =>
      locale.languageCode == 'ar'
          ? 'ملاحظات وتقييمات المستخدمين'
          : 'User feedback and ratings';
  String feedbackHeaderWithCount(int count) {
    if (locale.languageCode == 'ar') {
      return 'كل الملاحظات ($count)';
    }
    return 'All feedback ($count)';
  }

  String get settings => locale.languageCode == 'ar' ? 'الإعدادات' : 'Settings';
  String get account => locale.languageCode == 'ar' ? 'الحساب' : 'Account';
  String get application =>
      locale.languageCode == 'ar' ? 'التطبيق' : 'Application';
  String get other => locale.languageCode == 'ar' ? 'أخرى' : 'Other';
  String get help => locale.languageCode == 'ar' ? 'المساعدة' : 'Help';

  String get contactUs =>
      locale.languageCode == 'ar' ? 'تواصل معنا' : 'Contact us';
  String get ok => locale.languageCode == 'ar' ? 'حسناً' : 'OK';

  String get helpChooseContactMethod =>
      locale.languageCode == 'ar'
          ? 'اختر طريقة التواصل'
          : 'Choose how to contact';

  String get helpCallPhone =>
      locale.languageCode == 'ar' ? 'اتصال' : 'Call';

  String get helpSendSms =>
      locale.languageCode == 'ar' ? 'إرسال رسالة' : 'Send message';

  String get helpCouldNotOpenLink =>
      locale.languageCode == 'ar'
          ? 'تعذر فتح التطبيق. حاول مرة أخرى.'
          : 'Could not open the app. Please try again.';

  String get phone => locale.languageCode == 'ar' ? 'الهاتف' : 'Phone';

  String get faq =>
      locale.languageCode == 'ar'
          ? 'الأسئلة الشائعة'
          : 'Frequently Asked Questions';

  String get faqUploadInvoice =>
      locale.languageCode == 'ar'
          ? 'كيف أرفع فاتورتي؟'
          : 'How do I upload a new invoice?';

  String get faqUploadInvoiceAnswer =>
      locale.languageCode == 'ar'
          ? 'اضغط على زر رفع الفاتورة في الصفحة الرئيسية ثم اختر صورة أو ملف PDF.'
          : 'Click the Upload Invoice button on the homepage, then choose an image or PDF file.';

  String get faqTrackConsumption =>
      locale.languageCode == 'ar'
          ? 'كيف أتابع استهلاكي الشهري؟'
          : 'How do I track my monthly consumption?';

  String get faqTrackConsumptionAnswer =>
      locale.languageCode == 'ar'
          ? 'يمكنك مشاهدة الرسم البياني في صفحة تفاصيل الفاتورة.'
          : 'You can see the graph on the invoice details page.';
  String get aboutApp =>
      locale.languageCode == 'ar' ? 'عن التطبيق' : 'About Application';
  String get privacyPolicy =>
      locale.languageCode == 'ar' ? 'سياسة الخصوصية' : 'Privacy Policy';

  String get aboutAppTitle =>
      locale.languageCode == 'ar' ? 'عن التطبيق' : 'About App';
  String get aboutAppDescription =>
      locale.languageCode == 'ar'
          ? 'تطبيق المساعد الذكي يساعدك في تتبع فواتير الكهرباء والمياه وعرض التحليلات والاستهلاك.'
          : 'Smart Assistant helps you track electricity and water bills, view analytics and consumption.';
  String get appVersion => locale.languageCode == 'ar' ? 'الإصدار' : 'Version';

  String get privacyPolicyContent =>
      locale.languageCode == 'ar'
          ? '''سياسة الخصوصية

نحن نحترم خصوصيتك. البيانات التي تجمعها التطبيق تُستخدم فقط لـ:
• تقديم خدمة تتبع الفواتير والاستهلاك
• تحسين تجربة المستخدم
• لا نبيع أو نشارك بياناتك الشخصية مع أطراف ثالثة لأغراض تسويقية

بيانات الحساب وكلمة المرور محمية ومعالجة بشكل آمن. يمكنك طلب حذف بياناتك في أي وقت عبر التواصل معنا.'''
          : '''Privacy Policy

We respect your privacy. Data collected by the app is used only to:
• Provide bill and consumption tracking services
• Improve user experience
• We do not sell or share your personal data with third parties for marketing

Account data and passwords are protected and processed securely. You may request deletion of your data at any time by contacting us.''';

  String get language => locale.languageCode == 'ar' ? 'اللغة' : 'Language';
  String get darkMode =>
      locale.languageCode == 'ar' ? 'الوضع الداكن' : 'Dark Mode';
  String get profile =>
      locale.languageCode == 'ar' ? 'الملف الشخصي' : 'Profile';

  String get personalInformation =>
      locale.languageCode == 'ar'
          ? 'المعلومات الشخصية'
          : 'Personal Information';

  String get updatePersonalDetails =>
      locale.languageCode == 'ar'
          ? 'تحديث بياناتك الشخصية'
          : 'Update your personal details';

  String get nameLabel => locale.languageCode == 'ar' ? 'الاسم:' : 'Name:';

  String get edit => locale.languageCode == 'ar' ? 'تعديل' : 'Edit';

  String get saveChanges =>
      locale.languageCode == 'ar' ? 'حفظ التعديلات' : 'Save Changes';

  String get profileUpdated =>
      locale.languageCode == 'ar'
          ? 'تم تحديث البيانات بنجاح'
          : 'Profile updated successfully';

  String get profileUpdateError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء تحديث البيانات'
          : 'An error occurred while updating profile';
  String get editProfile =>
      locale.languageCode == 'ar' ? 'تعديل الملف' : 'Edit Profile';
  String get save => locale.languageCode == 'ar' ? 'حفظ' : 'Save';
  String get close => locale.languageCode == 'ar' ? 'إغلاق' : 'Close';
  String get noUsersFound =>
      locale.languageCode == 'ar' ? 'لا يوجد مستخدمون' : 'No users found.';

  String get registerSuccess =>
      locale.languageCode == 'ar'
          ? 'تم التسجيل بنجاح'
          : 'Registration successful';

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

  String get passwordResetNoUserForEmail =>
      locale.languageCode == 'ar'
          ? 'لا يوجد حساب بهذا البريد. تأكد من البريد أو سجّل حساباً جديداً.'
          : 'No account exists for this email. Check the address or register.';

  String get passwordResetGenericError =>
      locale.languageCode == 'ar'
          ? 'تعذر إرسال رابط إعادة التعيين. حاول مرة أخرى.'
          : 'Could not send the reset link. Please try again.';

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

  String get fullNameMaxLength =>
      locale.languageCode == 'ar'
          ? 'الاسم يجب ألا يتجاوز 30 حرفًا'
          : 'Full name must not exceed 30 characters';

  String get rememberMe =>
      locale.languageCode == 'ar' ? 'تذكرني' : 'Remember me';

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

  String get welcome => locale.languageCode == 'ar' ? 'مرحباً' : 'Welcome';

  String get welcomeAdmin =>
      locale.languageCode == 'ar' ? 'مرحباً، المدير!' : 'Welcome, Admin!';

  String get home => locale.languageCode == 'ar' ? 'الرئيسية' : 'Home';

  String get landingBadge =>
      locale.languageCode == 'ar'
          ? 'تحليل الفواتير الذكي'
          : 'Smart Bill Analysis';

  String get landingTitle =>
      locale.languageCode == 'ar'
          ? 'حلّل فواتيرك\nووفر بذكاء'
          : 'Analyze Your Bills\nSave Smarter';

  String get landingSubtitle =>
      locale.languageCode == 'ar'
          ? 'ارفع فواتير الكهرباء والمياه وتابع الاستهلاك واتخذ قرارات أفضل.'
          : 'Upload your water & electricity bills, track usage, and make smarter decisions.';

  String get landingGetStarted =>
      locale.languageCode == 'ar' ? 'ابدأ الآن' : 'Get Started';

  String get landingSignIn =>
      locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Sign In';

  String get userHomePage =>
      locale.languageCode == 'ar'
          ? 'هذه هي صفحة المستخدم الرئيسية'
          : 'This is the user home page';

  String get myBills => locale.languageCode == 'ar' ? 'فواتيري' : 'My Bills';

  String get aiChatbot =>
      locale.languageCode == 'ar' ? 'المساعد الذكي' : 'AI Chatbot';

  String get onlineNow =>
      locale.languageCode == 'ar' ? 'متصل الآن' : 'Online Now';

  String get chatbotWelcome =>
      locale.languageCode == 'ar'
          ? 'مرحباً! أنا مساعدك الذكي لتحليل فواتير الكهرباء والمياه. كيف يمكنني مساعدتك اليوم؟'
          : 'Hello! I am your smart assistant for analyzing your electricity and water bills. How can I help you today?';

  String get chatbotSampleQuestion =>
      locale.languageCode == 'ar'
          ? 'ما هو الاستهلاك الطبيعي؟'
          : 'What is normal consumption?';

  String get writeMessageHint =>
      locale.languageCode == 'ar' ? 'اكتب رسالتك...' : 'Write your message...';

  String get chatbotNormalConsumption =>
      locale.languageCode == 'ar'
          ? 'الاستهلاك الطبيعي يختلف حسب عدد أفراد المنزل والأجهزة. هل تريد مقارنة استهلاكك الشهري؟'
          : 'Normal consumption depends on household size and appliances. Would you like to compare your monthly usage?';

  String get chatbotBillHelp =>
      locale.languageCode == 'ar'
          ? 'يمكنني مساعدتك في فهم تفاصيل الفاتورة ومقارنة الاستهلاك. هل لديك رقم فاتورة محدد؟'
          : 'I can help you understand bill details and compare usage. Do you have a specific bill number?';

  String get chatbotHelp =>
      locale.languageCode == 'ar'
          ? 'أخبرني بما تحتاجه: فواتير، استهلاك، أو نصائح لتقليل المصروف.'
          : 'Tell me what you need: bills, consumption, or tips to reduce usage.';

  String get chatbotDefaultReply =>
      locale.languageCode == 'ar'
          ? 'فهمت. هل تريد أن أراجع فواتير الكهرباء أو المياه لهذا الشهر؟'
          : 'Got it. Would you like me to review your electricity or water bills for this month?';

  String get chatbotOutOfScope =>
      locale.languageCode == 'ar'
          ? 'أستطيع مساعدتك فقط في فواتير وتصنيفات التطبيق مثل الكهرباء، المياه، والإنترنت.'
          : 'I can only help with app bills and categories like electricity, water, and internet.';

  String get uploadNewBill =>
      locale.languageCode == 'ar' ? 'رفع فاتورة جديدة' : 'Upload new bill';

  String get uploadBillHint =>
      locale.languageCode == 'ar'
          ? 'اضغط هنا لرفع فاتورتك'
          : 'Click here to upload your bill';

  String get uploadBillTitle =>
      locale.languageCode == 'ar' ? 'رفع الفاتورة' : 'Upload Bill';

  String get uploadPdf =>
      locale.languageCode == 'ar' ? 'رفع ملف PDF' : 'Upload PDF';

  String get uploadPicture =>
      locale.languageCode == 'ar' ? 'رفع صورة' : 'Upload Picture';

  String get takeImage =>
      locale.languageCode == 'ar' ? 'التقاط صورة' : 'Take Image';

  String get uploadBillHintLong =>
      locale.languageCode == 'ar'
          ? 'يمكنك رفع فاتورة الكهرباء أو المياه كصورة أو ملف PDF. تُستخرج البيانات ثم تعرض لك لمراجعتها قبل الحفظ.'
          : 'Upload your electricity or water bill as a PDF or image. Data is extracted, then you can review it before saving.';

  String get analyzingBill =>
      locale.languageCode == 'ar'
          ? 'جاري استخراج البيانات من الفاتورة...'
          : 'Extracting bill data...';

  String get analysisResult =>
      locale.languageCode == 'ar' ? 'نتائج التحليل' : 'Analysis results';

  String get selectedFile => locale.languageCode == 'ar' ? 'الملف' : 'File';

  String get billType =>
      locale.languageCode == 'ar' ? 'نوع الفاتورة' : 'Bill type';

  String get billTypeElectricity =>
      locale.languageCode == 'ar' ? 'كهرباء' : 'Electricity';

  String get billTypeWater => locale.languageCode == 'ar' ? 'ماء' : 'Water';

  String get billingMonthTitle =>
      locale.languageCode == 'ar'
          ? 'فاتورة أي شهر / الفترة'
          : 'Billing month / period';

  String get currentMonthCharge =>
      locale.languageCode == 'ar'
          ? 'مبلغ الشهر الحالي'
          : 'Current month charge';

  String get consumptionDaysLabel =>
      locale.languageCode == 'ar' ? 'عدد أيام الاستهلاك' : 'Consumption days';

  String get consumptionElectricityHint =>
      locale.languageCode == 'ar'
          ? 'كيلوواط ساعة (kWh)'
          : 'Kilowatt-hours (kWh)';

  String get consumptionWaterHint =>
      locale.languageCode == 'ar' ? 'متر مكعب (m³)' : 'Cubic meters (m³)';

  String get accountNumber =>
      locale.languageCode == 'ar' ? 'رقم الحساب' : 'Account number';

  String get invoiceDate =>
      locale.languageCode == 'ar' ? 'تاريخ الفاتورة' : 'Invoice date';

  String get invoiceNumberTitle =>
      locale.languageCode == 'ar' ? 'رقم الفاتورة' : 'Invoice number';

  String get chartUnitKwh => locale.languageCode == 'ar' ? 'ك.و.س' : 'kWh';

  String get chartUnitWater => locale.languageCode == 'ar' ? 'م³' : 'm³';

  String get totalAmount =>
      locale.languageCode == 'ar' ? 'إجمالي المستحقات' : 'Total dues';

  String get currencyOmr => locale.languageCode == 'ar' ? 'ر.ع.' : 'OMR';

  String get taxAmount =>
      locale.languageCode == 'ar' ? 'الضريبة' : 'Tax amount';

  String get consumption =>
      locale.languageCode == 'ar' ? 'الاستهلاك' : 'Consumption';

  String get consumptionUnitField =>
      locale.languageCode == 'ar' ? 'وحدة الاستهلاك' : 'Consumption unit';

  String get period => locale.languageCode == 'ar' ? 'الفترة' : 'Period';

  String get fees => locale.languageCode == 'ar' ? 'الرسوم' : 'Fees';

  String get noDataFound =>
      locale.languageCode == 'ar' ? 'غير متوفر' : 'Not available';

  String get ocrError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء قراءة النص'
          : 'Failed to read text from image';

  String get noTextDetected =>
      locale.languageCode == 'ar'
          ? 'لم يتم العثور على نص قابل للقراءة. إذا كان الملف ممسوحاً ضوئياً، جرّب رفع صورة للصفحة.'
          : 'No readable text found. If this is a scanned document, try uploading a photo of the page.';

  String get pdfReadError =>
      locale.languageCode == 'ar'
          ? 'تعذّر فتح ملف PDF. تأكد أنه غير تالف أو غير محمي بكلمة مرور.'
          : 'Could not open this PDF. Make sure it is not corrupted or password-protected.';

  String get noPdfSelected =>
      locale.languageCode == 'ar'
          ? 'لم يتم اختيار ملف PDF'
          : 'No PDF file was selected';

  String get noGalleryImageSelected =>
      locale.languageCode == 'ar'
          ? 'لم يتم اختيار صورة'
          : 'No image was selected';

  String get noCameraCapture =>
      locale.languageCode == 'ar' ? 'لم يتم التقاط صورة' : 'No photo was taken';

  String get billProcessingError =>
      locale.languageCode == 'ar'
          ? 'تعذّر معالجة الفاتورة. حاول مرة أخرى.'
          : 'Could not process the bill. Please try again.';

  String get billSavedToMyBills =>
      locale.languageCode == 'ar'
          ? 'تم حفظ الفاتورة في صفحة فواتيري'
          : 'Bill saved in My Bills';

  String get billSavedChartsUpdatedHint =>
      locale.languageCode == 'ar'
          ? 'سيظهر الاستهلاك في الرسوم عند ضبط شهر الفوترة والاستهلاك.'
          : 'Charts update when billing month and consumption are set.';

  String get billReviewTitle =>
      locale.languageCode == 'ar' ? 'مراجعة الفاتورة' : 'Review bill';

  String get billReviewHint =>
      locale.languageCode == 'ar'
          ? 'صحّح البيانات إن لزم ثم اضغط حفظ.'
          : 'Adjust the fields if needed, then tap Save.';

  String get billReviewChartHint =>
      locale.languageCode == 'ar'
          ? '«شهر الفوترة» يحدد العمود في مخططات الاستهلاك بالصفحة الرئيسية. يُفضّل مطابقته لشهر الفاتورة.'
          : 'Billing month selects the bar in home consumption charts. Match it to the bill period when possible.';

  String get pickInvoiceDateAction =>
      locale.languageCode == 'ar' ? 'اختر تاريخ الفاتورة' : 'Pick invoice date';

  String get pickBillingMonthAction =>
      locale.languageCode == 'ar' ? 'اختر شهر الفوترة' : 'Pick billing month';

  String get billingMonthKeyField =>
      locale.languageCode == 'ar'
          ? 'شهر الفوترة (YYYY-MM)'
          : 'Billing month (YYYY-MM)';

  String get billReviewValidation =>
      locale.languageCode == 'ar'
          ? 'أدخل مبلغاً أو استهلاكاً أو رقم فاتورة أو شهراً على الأقل.'
          : 'Enter at least a total, consumption, invoice number, or billing month.';

  String get fieldRequired =>
      locale.languageCode == 'ar' ? 'هذا الحقل مطلوب' : 'This field is required';

  String get billReviewErrInvalidNumber =>
      locale.languageCode == 'ar'
          ? 'أدخل رقماً صالحاً أكبر من صفر'
          : 'Enter a valid number greater than zero';

  String get billReviewErrBillingKeyFormat =>
      locale.languageCode == 'ar'
          ? 'صيغة شهر الفوترة: YYYY-MM (مثال 2025-03)'
          : 'Billing month must be YYYY-MM (e.g. 2025-03)';

  String get chartInteractionHint =>
      locale.languageCode == 'ar'
          ? 'اضغط أو اسحب أفقياً لاستكشاف الأشهر'
          : 'Tap or drag horizontally to explore months';

  String get filterAll => locale.languageCode == 'ar' ? 'الكل' : 'All';

  String get filterElectricity =>
      locale.languageCode == 'ar' ? 'كهرباء' : 'Electricity';

  String get filterWater => locale.languageCode == 'ar' ? 'مياه' : 'Water';

  String get analysis => locale.languageCode == 'ar' ? 'تحليل' : 'Analysis';

  String get searchHint =>
      locale.languageCode == 'ar' ? 'بحث في الفواتير' : 'Search bills';

  String get sortAndFilter =>
      locale.languageCode == 'ar' ? 'ترتيب وتصفية' : 'Sort & Filter';
  String get sortByDateNewest =>
      locale.languageCode == 'ar' ? 'التاريخ (الأحدث)' : 'Date (Newest)';
  String get sortByDateOldest =>
      locale.languageCode == 'ar' ? 'التاريخ (الأقدم)' : 'Date (Oldest)';
  String get sortByType => locale.languageCode == 'ar' ? 'النوع' : 'Type';
  String get sortByConsumptionHigh =>
      locale.languageCode == 'ar' ? 'الاستهلاك (الأعلى)' : 'Consumption (High)';
  String get sortByConsumptionLow =>
      locale.languageCode == 'ar' ? 'الاستهلاك (الأقل)' : 'Consumption (Low)';
  String get deleteAll =>
      locale.languageCode == 'ar' ? 'حذف الكل' : 'Delete All';
  String get deleteSelected =>
      locale.languageCode == 'ar' ? 'حذف المحدد' : 'Delete Selected';
  String get selectAll =>
      locale.languageCode == 'ar' ? 'تحديد الكل' : 'Select All';
  String get deselectAll =>
      locale.languageCode == 'ar' ? 'إلغاء التحديد' : 'Deselect All';
  String get deleteAllConfirm =>
      locale.languageCode == 'ar'
          ? 'حذف جميع الفواتير؟ لا يمكن التراجع.'
          : 'Delete all bills? This cannot be undone.';
  String get deleteSelectedConfirm =>
      locale.languageCode == 'ar'
          ? 'حذف الفواتير المحددة؟'
          : 'Delete selected bills?';

  String get compareMonthlyConsumption =>
      locale.languageCode == 'ar'
          ? 'قارن الاستهلاك الشهري'
          : 'Compare monthly consumption';

  String get chartPeriodLabel =>
      locale.languageCode == 'ar' ? 'الفترة' : 'Period';

  String get chartMonthsShort3 =>
      locale.languageCode == 'ar' ? '3 شهور' : '3 mo';

  String get chartMonthsShort6 =>
      locale.languageCode == 'ar' ? '6 شهور' : '6 mo';

  String get chartMonthsShort12 =>
      locale.languageCode == 'ar' ? '12 شهر' : '12 mo';

  String get chartFootnoteOcr =>
      locale.languageCode == 'ar'
          ? 'الأشهر بلا فاتورة تظهر 0. القيم من الاستهلاك المحفوظ بعد التحليل (OCR/ PDF).'
          : 'Months with no bill show 0. Values use saved consumption from analysis (OCR/PDF).';

  String smartAnalyticsYoyElectric(double pct) {
    final p = pct.toStringAsFixed(0);
    return locale.languageCode == 'ar'
        ? 'الكهرباء مقارنة بنفس الشهر من العام الماضي: ${pct >= 0 ? '+' : ''}$p%.'
        : 'Electricity vs same month last year: ${pct >= 0 ? '+' : ''}$p%.';
  }

  String smartAnalyticsYoyWater(double pct) {
    final p = pct.toStringAsFixed(0);
    return locale.languageCode == 'ar'
        ? 'الماء مقارنة بنفس الشهر من العام الماضي: ${pct >= 0 ? '+' : ''}$p%.'
        : 'Water vs same month last year: ${pct >= 0 ? '+' : ''}$p%.';
  }

  String get monthlyWaterUsage =>
      locale.languageCode == 'ar'
          ? 'استخدام المياه الشهري'
          : 'Monthly water usage';

  String get monthlyElectricityUsage =>
      locale.languageCode == 'ar'
          ? 'استخدام الكهرباء الشهري'
          : 'Monthly electricity usage';

  String get smartAnalytics =>
      locale.languageCode == 'ar' ? 'تحليلات ذكية' : 'Smart analytics';

  String smartAnalyticsAvgElectric3m(double kwh) {
    final v = kwh.toStringAsFixed(0);
    return locale.languageCode == 'ar'
        ? 'متوسط آخر 3 أشهر (كهرباء): $v ك.و.س'
        : 'Last 3-month avg (electricity): $v kWh';
  }

  String smartAnalyticsAvgWater3m(double m3) {
    final v = m3.toStringAsFixed(1);
    return locale.languageCode == 'ar'
        ? 'متوسط آخر 3 أشهر (ماء): $v م³'
        : 'Last 3-month avg (water): $v m³';
  }

  String get smartAnalyticsNoElectricityData =>
      locale.languageCode == 'ar'
          ? 'لا بيانات كهرباء كافية بعد.'
          : 'Not enough electricity data yet.';

  String get smartAnalyticsNoWaterData =>
      locale.languageCode == 'ar'
          ? 'لا بيانات مياه كافية بعد.'
          : 'Not enough water data yet.';

  String smartAnalyticsSpikeElectric(double pct) {
    final p = pct.toStringAsFixed(0);
    return locale.languageCode == 'ar'
        ? 'تنبيه: استهلاك الكهرباء هذا الشهر أعلى بحوالي $p% من متوسط الأشهر الثلاثة السابقة.'
        : 'Heads up: this month’s electricity use is ~$p% above your prior 3-month average.';
  }

  String smartAnalyticsSpikeWater(double pct) {
    final p = pct.toStringAsFixed(0);
    return locale.languageCode == 'ar'
        ? 'تنبيه: استهلاك الماء هذا الشهر أعلى بحوالي $p% من متوسط الأشهر الثلاثة السابقة.'
        : 'Heads up: this month’s water use is ~$p% above your prior 3-month average.';
  }

  String get smartAnalyticsFallbackPrimary =>
      locale.languageCode == 'ar'
          ? 'أضف فواتير باستهلاك واضح لرؤية متوسطاتك ومقارنات ذكية.'
          : 'Add bills with consumption to see your averages and smart comparisons.';

  String get smartAnalyticsFallbackSecondary =>
      locale.languageCode == 'ar'
          ? 'الرسوم البيانية أعلاه تُظهر الاتجاه الشهري عند توفر البيانات.'
          : 'The charts above show monthly trends when data is available.';

  String get categoriesOverview =>
      locale.languageCode == 'ar' ? 'التصنيفات' : 'Categories';

  String get fastActions =>
      locale.languageCode == 'ar' ? 'إجراءات سريعة' : 'Fast actions';

  String get adminHomePage =>
      locale.languageCode == 'ar'
          ? 'هذه هي صفحة المدير الرئيسية'
          : 'This is the admin home page';

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

  String get emailAlreadyRegistered =>
      locale.languageCode == 'ar'
          ? 'البريد الإلكتروني مسجل مسبقًا'
          : 'Email is already registered';

  String get registerError =>
      locale.languageCode == 'ar'
          ? 'حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى'
          : 'An error occurred during registration. Please try again';

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

  String get logout => locale.languageCode == 'ar' ? 'تسجيل الخروج' : 'Logout';

  String get logoutConfirm =>
      locale.languageCode == 'ar'
          ? 'هل أنت متأكد من تسجيل الخروج؟'
          : 'Are you sure you want to logout?';

  String get accountsTitle =>
      locale.languageCode == 'ar' ? 'الحسابات' : 'Accounts';

  String get addAccount =>
      locale.languageCode == 'ar' ? 'إضافة حساب' : 'Add account';

  String get accountLimitReached =>
      locale.languageCode == 'ar'
          ? 'يمكن حفظ حسابين فقط على هذا الجهاز. أزل حساباً من القائمة ثم أعد المحاولة.'
          : 'Only two accounts can be saved on this device. Remove one from the list and try again.';

  String get accountLimitReachedShort =>
      locale.languageCode == 'ar'
          ? 'الحد: حسابان محفوظان على الجهاز'
          : 'Limit: two saved accounts on this device';

  String get accountNotSavedDeviceLimit =>
      locale.languageCode == 'ar'
          ? 'تم تسجيل الدخول. لم يُحفظ الحساب في القائمة السريعة لأن الحد هو حسابان على هذا الجهاز.'
          : 'Signed in. This account was not added to quick switch (limit of two on this device).';

  String get loginAddAccountTitle =>
      locale.languageCode == 'ar'
          ? 'إضافة حساب آخر'
          : 'Add another account';

  String get currentAccountBadge =>
      locale.languageCode == 'ar' ? 'الحالي' : 'Current';

  String get accountSwitchError =>
      locale.languageCode == 'ar'
          ? 'تعذر تبديل الحساب. حاول تسجيل الدخول يدوياً.'
          : 'Could not switch account. Try signing in manually.';

  String get accountSwitchEnterPasswordTitle =>
      locale.languageCode == 'ar'
          ? 'أدخل كلمة المرور لهذا الحساب (مرة واحدة)'
          : 'Enter password for this account (once)';

  String get accountSwitchEnterPasswordHint =>
      locale.languageCode == 'ar'
          ? 'يُحفظ على الجهاز بشكل آمن للتبديل السريع لاحقاً.'
          : 'Saved securely on this device for quick switching later.';

  String get accountSwitchConfirm =>
      locale.languageCode == 'ar' ? 'متابعة' : 'Continue';

  String get logoutChooseTitle =>
      locale.languageCode == 'ar'
          ? 'كيف تريد تسجيل الخروج؟'
          : 'How would you like to sign out?';

  String get logoutFromCurrentDevice =>
      locale.languageCode == 'ar'
          ? 'من هذا الحساب فقط'
          : 'This account only';

  String get logoutFromCurrentDeviceSubtitle =>
      locale.languageCode == 'ar'
          ? 'يبقى باقي الحسابات المحفوظة على هذا الجهاز'
          : 'Other saved accounts stay on this device';

  String get logoutFromAllAccounts =>
      locale.languageCode == 'ar'
          ? 'من جميع الحسابات'
          : 'From all accounts';

  String get logoutFromAllAccountsSubtitle =>
      locale.languageCode == 'ar'
          ? 'حذف كل الحسابات المحفوظة من هذا الجهاز'
          : 'Remove all saved accounts from this device';

  String get savedAccountsQuickLogin =>
      locale.languageCode == 'ar'
          ? 'حساباتك على هذا الجهاز'
          : 'Your accounts on this device';

  String get removeSavedAccountAction =>
      locale.languageCode == 'ar'
          ? 'إزالة من الجهاز'
          : 'Remove from this device';

  String get removeSavedAccountTitle =>
      locale.languageCode == 'ar'
          ? 'إزالة الحساب المحفوظ؟'
          : 'Remove saved account?';

  String removeSavedAccountMessage(String email) =>
      locale.languageCode == 'ar'
          ? 'سيتم حذف بيانات تسجيل الدخول المحفوظة لـ ($email) من هذا الجهاز فقط. يمكنك تسجيل الدخول لاحقاً.'
          : 'Saved sign-in for ($email) will be removed from this device only. You can sign in again anytime.';

  String get accountRemovedFromDevice =>
      locale.languageCode == 'ar'
          ? 'تمت إزالة الحساب من هذا الجهاز'
          : 'Account removed from this device';

  String get cancel => locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel';
  String get add => locale.languageCode == 'ar' ? 'إضافة' : 'Add';
  String get update => locale.languageCode == 'ar' ? 'تحديث' : 'Update';
  String get delete => locale.languageCode == 'ar' ? 'حذف' : 'Delete';
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
