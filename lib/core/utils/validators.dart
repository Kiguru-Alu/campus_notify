import '../constants/campus.dart';

/// No Flutter imports, so these are directly unit testable. Each returns
/// null when the value is acceptable, matching [FormFieldValidator].
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// A usability guard, not a security control. Firestore rules reject
  /// off-domain accounts server side.
  static String? campusEmail(String? value) {
    final input = value?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return 'Enter your campus email';
    if (!_email.hasMatch(input)) return 'That does not look like an email address';
    // final isStudent = input.endsWith('@${Campus.emailDomain}');
    // final isStaff = input.endsWith('@${Campus.staffEmailDomain}');
    // final isTestAccount = input.endsWith('@gmail.com');
    // if (!isStudent && !isStaff && !isTestAccount) {
    //   return 'Use your @${Campus.emailDomain} address';
    // }
    final isStudent = input.endsWith('@${Campus.emailDomain}');
    final isStaff = input.endsWith('@${Campus.staffEmailDomain}');
    if (!isStudent && !isStaff) {
      return 'Use your @${Campus.emailDomain} address';
    }
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Enter a password';
    if (input.length < 8) return 'Use at least 8 characters';
    if (!input.contains(RegExp(r'[A-Za-z]')) ||
        !input.contains(RegExp(r'[0-9]'))) {
      return 'Mix letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your full name';
    if (input.length < 3) return 'Enter your full name';
    return null;
  }

  static String? incidentTitle(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Give the issue a short title';
    if (input.length < 8) return 'Add a little more detail';
    if (input.length > 90) return 'Keep the title under 90 characters';
    return null;
  }

  static String? incidentDescription(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Describe what is wrong';
    if (input.length < 20) {
      return 'Add more detail so the team knows what to bring';
    }
    if (input.length > 1200) return 'Keep the description under 1200 characters';
    return null;
  }

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }
}
