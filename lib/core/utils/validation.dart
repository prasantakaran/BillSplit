abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r"^[\w.!#$%&'*+/=?^`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static final RegExp _mobilePattern = RegExp(r'^[6-9]\d{9}$');

  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = required(value, field: 'Full name');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 3) {
      return 'Enter your full name (min 3 characters)';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, field: 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!_hasLetter.hasMatch(value) || !_hasDigit.hasMatch(value)) {
      return 'Use at least one letter and one number';
    }
    return null;
  }

  static String? mobile(String? value) {
    final requiredError = required(value, field: 'Mobile number');
    if (requiredError != null) return requiredError;
    if (!_mobilePattern.hasMatch(value!.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? city(String? value) => required(value, field: 'City');
}
