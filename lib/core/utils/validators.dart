// Form Validation Methods
class Validators {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    bool isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
    if (!isValid) return 'Enter a valid email address';
    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters required';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    return null;
  }

  // Required Field Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Minimum 2 characters required';
    return null;
  }

  // Phone Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    bool isValid = RegExp(r'^(\+8801|01)[3-9]\d{8}$').hasMatch(value);
    if (!isValid) return 'Enter valid Bangladesh number (01XXXXXXXXX)';
    return null;
  }

  // Consultation Fee Validation
  static String? validateFee(String? value) {
    if (value == null || value.isEmpty) return 'Consultation fee is required';
    double? fee = double.tryParse(value);
    if (fee == null || fee <= 0) return 'Enter a valid fee amount';
    return null;
  }

  // Password Strength Checker
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    if (score <= 2) return 'Weak';
    if (score <= 3) return 'Fair';
    return 'Strong';
  }

  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
