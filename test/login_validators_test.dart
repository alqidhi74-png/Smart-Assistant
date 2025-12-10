import 'package:flutter_test/flutter_test.dart';
import 'package:email_validator/email_validator.dart';

String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email required';
  }
  if (!EmailValidator.validate(value)) {
    return 'Enter valid email';
  }
  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password required';
  }
  if (value.length < 6) {
    return 'Password too short';
  }
  return null;
}

void main() {
  group('Email Validator', () {
    test('returns error if empty', () {
      expect(emailValidator(''), 'Email required');
      print('Email empty test passed');
    });

    test('returns error if invalid', () {
      expect(emailValidator('invalidEmail'), 'Enter valid email');
      print('Email invalid test passed');
    });

    test('returns null if valid', () {
      expect(emailValidator('test@example.com'), null);
      print('Email valid test passed');
    });
  });

  group('Password Validator', () {
    test('returns error if empty', () {
      expect(passwordValidator(''), 'Password required');
      print('Password empty test passed');
    });

    test('returns error if too short', () {
      expect(passwordValidator('123'), 'Password too short');
      print('Password short test passed');
    });

    test('returns null if valid', () {
      expect(passwordValidator('StrongPass123'), null);
      print('Password valid test passed');
    });
  });
}
