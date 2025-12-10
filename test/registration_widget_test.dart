import 'package:flutter_test/flutter_test.dart';
import 'package:email_validator/email_validator.dart';

class RegistrationValidators {
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required.';
    }
    if (value.length > 30) {
      return 'Full name must not exceed 30 characters.';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Full name must contain only letters and spaces.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }
    if (!RegExp(r'^[79]\d{7}$').hasMatch(value)) {
      return 'Phone number must be 8 digits and start with 7 or 9 (Oman).';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8 || value.length > 16) {
      return 'Password must be between 8 and 16 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password.';
    }
    if (password != confirm) {
      return 'Passwords do not match.';
    }
    return null;
  }
}

void main() {
  group('RegistrationValidators - Full Name', () {
    test('should return error if empty', () {
      expect(RegistrationValidators.validateFullName(''), 'Full name is required.');
      print('Full Name empty test passed');
    });

    test('should return error if too long', () {
      expect(RegistrationValidators.validateFullName('A' * 31),
          'Full name must not exceed 30 characters.');
      print('Full Name too long test passed');
    });

    test('should return error if contains invalid chars', () {
      expect(RegistrationValidators.validateFullName('John123'),
          'Full name must contain only letters and spaces.');
      print('Full Name invalid chars test passed');
    });

    test('should return null if valid', () {
      expect(RegistrationValidators.validateFullName('John Doe'), null);
      print('Full Name valid test passed');
    });
  });

  group('RegistrationValidators - Email', () {
    test('should return error if empty', () {
      expect(RegistrationValidators.validateEmail(''), 'Email is required.');
      print('Email empty test passed');
    });

    test('should return error if invalid', () {
      expect(RegistrationValidators.validateEmail('not-an-email'),
          'Please enter a valid email address.');
      print('Email invalid test passed');
    });

    test('should return null if valid', () {
      expect(RegistrationValidators.validateEmail('test@example.com'), null);
      print('Email valid test passed');
    });
  });

  group('RegistrationValidators - Phone', () {
    test('should return error if empty', () {
      expect(RegistrationValidators.validatePhone(''), 'Phone number is required.');
      print('Phone empty test passed');
    });

    test('should return error if not Omani format', () {
      expect(RegistrationValidators.validatePhone('61234567'),
          'Phone number must be 8 digits and start with 7 or 9 (Oman).');
      print('Phone invalid format test passed');
    });

    test('should return null if valid', () {
      expect(RegistrationValidators.validatePhone('91234567'), null);
      print('Phone valid test passed');
    });
  });

  group('RegistrationValidators - Password', () {
    test('should return error if too short', () {
      expect(RegistrationValidators.validatePassword('Ab1!'),
          'Password must be between 8 and 16 characters.');
      print('Password too short test passed');
    });

    test('should return error if missing uppercase', () {
      expect(RegistrationValidators.validatePassword('password1!'),
          'Password must contain at least one uppercase letter.');
      print('Password missing uppercase test passed');
    });

    test('should return error if missing lowercase', () {
      expect(RegistrationValidators.validatePassword('PASSWORD1!'),
          'Password must contain at least one lowercase letter.');
      print('Password missing lowercase test passed');
    });

    test('should return error if missing number', () {
      expect(RegistrationValidators.validatePassword('Password!'),
          'Password must contain at least one number.');
      print('Password missing number test passed');
    });

    test('should return error if missing special char', () {
      expect(RegistrationValidators.validatePassword('Password1'),
          'Password must contain at least one special character.');
      print('Password missing special char test passed');
    });

    test('should return null if valid', () {
      expect(RegistrationValidators.validatePassword('Password1!'), null);
      print('Password valid test passed');
    });
  });

  group('RegistrationValidators - Confirm Password', () {
    test('should return error if empty', () {
      expect(RegistrationValidators.validateConfirmPassword('Password1!', ''),
          'Please confirm your password.');
      print('Confirm Password empty test passed');
    });

    test('should return error if not matching', () {
      expect(RegistrationValidators.validateConfirmPassword('Password1!', 'Password2!'),
          'Passwords do not match.');
      print('Confirm Password not matching test passed');
    });

    test('should return null if matching', () {
      expect(RegistrationValidators.validateConfirmPassword('Password1!', 'Password1!'),
          null);
      print('Confirm Password matching test passed');
    });
  });

  tearDownAll(() {
    print('All registration validator tests passed successfully!');
  });
}
