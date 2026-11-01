import '../constants/app_constants.dart';

/// Pure functions (no Flutter imports), so they are easy to unit test
/// and reusable across auth screens.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email address';
    if (!_emailPattern.hasMatch(text)) {
      return 'Enter a valid email, like you@example.com';
    }
    return null;
  }

  /// For creating a password (sign up): enforces the minimum length.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please create a password';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Use at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  /// For entering an existing password (login): only checks it isn't empty.
  /// Length rules don't belong here; the server decides if it's correct.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
