import 'package:pars_validator/pars_validator.dart';

/// Comprehensive validation utilities with security focus
/// 
/// Provides input validation for forms with emphasis on:
/// - XSS prevention
/// - SQL injection prevention  
/// - Data format validation
/// - Security best practices
class Validators {
  static String? simpleFieldEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return "فیلد نمی‌تواند خالی باشد.";
    }

    return null;
  }

  static String? companyValidation(String? value) {
    if (value == null || value.isEmpty) {
      return "لطفاً کد ملی را وارد کنید.";
    }

    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return "شناسه ملی باید 11 رقم و فقط شامل اعداد باشد.";
    }

    return null;
  }

  static String? iranianNationalCodeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "لطفاً کد ملی را وارد کنید.";
    }
    bool isValid = National.isNationalIDValid(value);

    if (!isValid) {
      return "کد ملی وارد شده معتبر نیست.";
    }

    return null;
  }

  static String? phoneNumber(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفا شماره تلفن را وارد کنید";
      }
      bool isValid = Phone.isMobileNumberValid(value);

      if (!isValid) {
        return "شماره تلفن وارد شده نامعتبر است";
      }
    }

    return null;
  }

  static String? landPhoneNumber(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفا شماره تلفن را وارد کنید";
      }
      bool isValid = Phone.isLandlineNumberValid(value);

      if (!isValid) {
        return "شماره تلفن وارد شده نامعتبر است";
      }
    }
    return null;
  }

  static String? post(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفاً کدپستی را وارد کنید.";
      }
      bool isValid = National.isValidPostalCode(value);

      if (!isValid) {
        return "کدپستی وارد شده نامعتبر است";
      }
    }
    return null;
  }

  static String? fax(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفاً شماره فکس را وارد کنید.";
      }
      // فرض بر اینکه فکس شبیه تلفن ثابت هست
      if (!RegExp(r'^0\d{10}$').hasMatch(value)) {
        return "شماره فکس وارد شده نامعتبر است.";
      }
    }
    return null;
  }

  static String? email(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفاً ایمیل را وارد کنید.";
      }

      bool isValid = Phone.isEmailValid(value);
      if (!isValid) {
        return "ایمیل وارد شده معتبر نیست.";
      }
    }
    return null;
  }

  static String? website(String? value, {bool? optional = false}) {
    if (optional == false) {
      if (value == null || value.isEmpty) {
        return "لطفاً آدرس وب‌سایت را وارد کنید.";
      }
      if (!RegExp(
        r"^(https?:\/\/)?([\w\-]+\.)+[\w\-]{2,}(\/[\w\-._~:/?#[\]@!$&'()*+,;=.]+)?$",
      ).hasMatch(value)) {
        return "آدرس وب‌سایت معتبر نیست.";
      }
    }
    return null;
  }

  // ========================================
  // SECURITY-FOCUSED VALIDATORS
  // ========================================

  /// Validates and sanitizes text input to prevent XSS attacks
  /// 
  /// Checks for:
  /// - Script tags
  /// - JavaScript protocols
  /// - Event handlers
  /// - Data URIs with scripts
  static String? secureText(String? value, {
    bool required = false,
    int maxLength = 1000,
    String? fieldName,
  }) {
    final field = fieldName ?? 'فیلد';
    
    if (required && (value == null || value.trim().isEmpty)) {
      return '$field نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Check for dangerous patterns
    final dangerousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onload, etc.
      RegExp(r'data:.*?script', caseSensitive: false),
      RegExp(r'<iframe[^>]*>', caseSensitive: false),
      RegExp(r'<object[^>]*>', caseSensitive: false),
      RegExp(r'<embed[^>]*>', caseSensitive: false),
      RegExp(r'<svg[^>]*onload', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(value)) {
        return '$field شامل محتوای نامعتبر است';
      }
    }
    
    if (value.length > maxLength) {
      return '$field نمی‌تواند بیش از $maxLength کاراکتر باشد';
    }
    
    return null;
  }

  /// Validates password with security requirements
  /// 
  /// Enforces:
  /// - Minimum length
  /// - Complexity requirements
  /// - Common password prevention
  static String? securePassword(String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'رمز عبور نمی‌تواند خالی باشد';
    }
    
    if (value.length < minLength) {
      return 'رمز عبور باید حداقل $minLength کاراکتر باشد';
    }
    
    // Check for common weak passwords
    final commonPasswords = [
      '12345678', 'password', '123456789', 'qwerty', 
      'abc123', 'password123', '123123', 'admin'
    ];
    
    if (commonPasswords.contains(value.toLowerCase())) {
      return 'رمز عبور انتخابی بسیار ضعیف است';
    }
    
    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
      return 'رمز عبور باید شامل حداقل یک حرف بزرگ باشد';
    }
    
    if (requireLowercase && !RegExp(r'[a-z]').hasMatch(value)) {
      return 'رمز عبور باید شامل حداقل یک حرف کوچک باشد';
    }
    
    if (requireNumbers && !RegExp(r'[0-9]').hasMatch(value)) {
      return 'رمز عبور باید شامل حداقل یک عدد باشد';
    }
    
    if (requireSpecialChars && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'رمز عبور باید شامل حداقل یک کاراکتر خاص باشد';
    }
    
    return null;
  }

  /// Validates numeric input with range checking
  static String? secureNumeric(String? value, {
    bool required = false,
    double? min,
    double? max,
    bool allowDecimals = true,
    String? fieldName,
  }) {
    final field = fieldName ?? 'فیلد';
    
    if (required && (value == null || value.trim().isEmpty)) {
      return '$field نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Remove any potential injection characters
    if (RegExp(r'[^\d.\-+]').hasMatch(value)) {
      return '$field فقط می‌تواند شامل اعداد باشد';
    }
    
    final numericValue = allowDecimals ? double.tryParse(value) : int.tryParse(value);
    
    if (numericValue == null) {
      return '$field باید یک عدد معتبر باشد';
    }
    
    if (min != null && numericValue < min) {
      return '$field باید حداقل $min باشد';
    }
    
    if (max != null && numericValue > max) {
      return '$field باید حداکثر $max باشد';
    }
    
    return null;
  }

  /// Validates file paths and names to prevent directory traversal
  static String? secureFileName(String? value, {
    bool required = false,
    List<String> allowedExtensions = const [],
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'نام فایل نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Check for directory traversal attempts
    if (value.contains('..') || 
        value.contains('/') || 
        value.contains('\\') ||
        value.startsWith('.')) {
      return 'نام فایل نامعتبر است';
    }
    
    // Check for dangerous file names
    final dangerousNames = ['con', 'prn', 'aux', 'nul', 'com1', 'com2', 'lpt1', 'lpt2'];
    if (dangerousNames.contains(value.toLowerCase())) {
      return 'نام فایل مجاز نیست';
    }
    
    // Check file extension if restrictions exist
    if (allowedExtensions.isNotEmpty) {
      final extension = value.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        return 'فرمت فایل مجاز نیست. فرمت‌های مجاز: ${allowedExtensions.join(', ')}';
      }
    }
    
    return null;
  }

  /// Validates URLs with security checks
  static String? secureUrl(String? value, {
    bool required = false,
    List<String> allowedSchemes = const ['http', 'https'],
    List<String> blockedDomains = const [],
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'آدرس اینترنتی نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Basic URL format validation
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]{2,}(\/[\w\-._~:/?#[\]@!$&\'()*+,;=.]+)?$',
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(value)) {
      return 'آدرس اینترنتی نامعتبر است';
    }
    
    try {
      final uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
      
      // Check allowed schemes
      if (!allowedSchemes.contains(uri.scheme)) {
        return 'فقط آدرس‌های ${allowedSchemes.join(' و ')} مجاز هستند';
      }
      
      // Check blocked domains
      if (blockedDomains.contains(uri.host)) {
        return 'این دامنه مجاز نیست';
      }
      
      // Check for suspicious patterns
      if (uri.host.contains('localhost') || 
          uri.host.startsWith('127.') ||
          uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.')) {
        return 'آدرس‌های داخلی مجاز نیستند';
      }
      
    } catch (e) {
      return 'آدرس اینترنتی نامعتبر است';
    }
    
    return null;
  }

  /// Sanitizes HTML input by removing dangerous tags and attributes
  static String sanitizeHtml(String input) {
    // Remove script tags
    String sanitized = input.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    
    // Remove dangerous attributes
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=\s*["\'][^"\']*["\']', caseSensitive: false), '');
    
    // Remove javascript: protocols
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    
    // Remove dangerous tags
    final dangerousTags = ['iframe', 'object', 'embed', 'form', 'input', 'button'];
    for (final tag in dangerousTags) {
      sanitized = sanitized.replaceAll(RegExp('<$tag[^>]*>', caseSensitive: false), '');
      sanitized = sanitized.replaceAll(RegExp('</$tag>', caseSensitive: false), '');
    }
    
    return sanitized;
  }

  /// Validates Iranian bank card numbers
  static String? bankCardNumber(String? value, {bool required = false}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'شماره کارت نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Remove spaces and dashes
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Check length (should be 16 digits)
    if (!RegExp(r'^\d{16}$').hasMatch(cleanValue)) {
      return 'شماره کارت باید 16 رقم باشد';
    }
    
    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanValue.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanValue[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'شماره کارت نامعتبر است';
    }
    
    return null;
  }

  /// Validates Iranian SHEBA (bank account) numbers
  static String? shebaNumber(String? value, {bool required = false}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'شماره شبا نمی‌تواند خالی باشد';
    }
    
    if (value == null || value.isEmpty) return null;
    
    // Remove spaces, dashes, and IR prefix
    String cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (cleanValue.startsWith('IR')) {
      cleanValue = cleanValue.substring(2);
    }
    
    // Check length (should be 24 digits)
    if (!RegExp(r'^\d{24}$').hasMatch(cleanValue)) {
      return 'شماره شبا باید 24 رقم باشد';
    }
    
    // IBAN validation for Iran
    final rearranged = cleanValue.substring(4) + '1827' + cleanValue.substring(0, 4);
    BigInt ibanNumber = BigInt.parse(rearranged);
    
    if (ibanNumber % BigInt.from(97) != BigInt.one) {
      return 'شماره شبا نامعتبر است';
    }
    
    return null;
  }
}
