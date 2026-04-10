import 'package:firebase_auth/firebase_auth.dart';

import '../constants/language.dart';

/// Where the Firebase Auth error is shown (wording / fallback differs per flow).
enum FirebaseAuthMessageContext {
  login,
  register,
  forgotPassword,
  changePassword,
}

/// Single place for [FirebaseAuthException.code] → user-visible [String].
String firebaseAuthUserMessage(
  FirebaseAuthException e,
  AppLocalizations loc, {
  required FirebaseAuthMessageContext context,
}) {
  switch (e.code) {
    case 'network-request-failed':
    case 'network_error':
    case 'network-error':
      return loc.networkError;
    case 'too-many-requests':
      return loc.tooManyRequests;
    default:
      break;
  }

  switch (context) {
    case FirebaseAuthMessageContext.login:
      switch (e.code) {
        case 'user-disabled':
          return loc.userDisabled;
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
        case 'invalid-email':
          return loc.invalidEmailOrPassword;
        default:
          return loc.invalidEmailOrPassword;
      }
    case FirebaseAuthMessageContext.register:
      switch (e.code) {
        case 'email-already-in-use':
          return loc.emailAlreadyRegistered;
        case 'weak-password':
          return loc.passwordWeak;
        case 'invalid-email':
          return loc.registerError;
        default:
          return loc.registerError;
      }
    case FirebaseAuthMessageContext.forgotPassword:
      switch (e.code) {
        case 'invalid-email':
          return loc.validEmail;
        case 'user-not-found':
          return loc.passwordResetNoUserForEmail;
        default:
          return loc.passwordResetGenericError;
      }
    case FirebaseAuthMessageContext.changePassword:
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return loc.currentPasswordIncorrect;
        case 'weak-password':
          return loc.passwordWeak;
        case 'requires-recent-login':
          return loc.requiresRecentLogin;
        default:
          return loc.passwordChangeError;
      }
  }
}
