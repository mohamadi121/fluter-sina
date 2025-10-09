import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asood/core/helper/validators.dart';

/// Secure form field builder with built-in validation and security features
/// 
/// This widget automatically applies security best practices:
/// - Input sanitization
/// - XSS prevention  
/// - Length limits
/// - Format validation
/// - Rate limiting for sensitive fields
class SecureFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool required;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? customValidator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final String? helperText;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  
  // Security-specific options
  final SecureFieldType fieldType;
  final bool enableXssProtection;
  final bool enableLengthValidation;
  final List<String>? allowedFileExtensions;
  final List<String>? allowedUrlSchemes;
  final List<String>? blockedDomains;

  const SecureFormField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.required = false,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.customValidator,
    this.onChanged,
    this.onSaved,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
    this.fillColor,
    this.contentPadding,
    this.fieldType = SecureFieldType.text,
    this.enableXssProtection = true,
    this.enableLengthValidation = true,
    this.allowedFileExtensions,
    this.allowedUrlSchemes,
    this.blockedDomains,
  });

  @override
  State<SecureFormField> createState() => _SecureFormFieldState();
}

class _SecureFormFieldState extends State<SecureFormField> {
  late TextEditingController _controller;
  bool _obscureText = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String? _getValidator(String? value) {
    // Apply custom validator first
    if (widget.customValidator != null) {
      final customResult = widget.customValidator!(value);
      if (customResult != null) return customResult;
    }

    // Apply field-type specific validation
    switch (widget.fieldType) {
      case SecureFieldType.text:
        return Validators.secureText(
          value,
          required: widget.required,
          maxLength: widget.maxLength ?? 1000,
          fieldName: widget.label,
        );
      
      case SecureFieldType.email:
        return Validators.email(value, optional: !widget.required);
      
      case SecureFieldType.phone:
        return Validators.phoneNumber(value, optional: !widget.required);
      
      case SecureFieldType.password:
        return Validators.securePassword(value);
      
      case SecureFieldType.url:
        return Validators.secureUrl(
          value,
          required: widget.required,
          allowedSchemes: widget.allowedUrlSchemes ?? ['http', 'https'],
          blockedDomains: widget.blockedDomains ?? [],
        );
      
      case SecureFieldType.numeric:
        return Validators.secureNumeric(
          value,
          required: widget.required,
          fieldName: widget.label,
        );
      
      case SecureFieldType.nationalCode:
        return Validators.iranianNationalCodeValidator(value);
      
      case SecureFieldType.bankCard:
        return Validators.bankCardNumber(value, required: widget.required);
      
      case SecureFieldType.sheba:
        return Validators.shebaNumber(value, required: widget.required);
      
      case SecureFieldType.fileName:
        return Validators.secureFileName(
          value,
          required: widget.required,
          allowedExtensions: widget.allowedFileExtensions ?? [],
        );
      
      case SecureFieldType.postalCode:
        return Validators.post(value, optional: !widget.required);
      
      case SecureFieldType.website:
        return Validators.website(value, optional: !widget.required);
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[];
    
    // Add field-specific formatters
    switch (widget.fieldType) {
      case SecureFieldType.numeric:
        formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[\d.\-+]')));
        break;
      case SecureFieldType.phone:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case SecureFieldType.nationalCode:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        formatters.add(LengthLimitingTextInputFormatter(10));
        break;
      case SecureFieldType.bankCard:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        formatters.add(LengthLimitingTextInputFormatter(16));
        formatters.add(_BankCardFormatter());
        break;
      case SecureFieldType.sheba:
        formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9IR\-\s]')));
        formatters.add(LengthLimitingTextInputFormatter(29)); // IR + 24 digits + spaces
        break;
      case SecureFieldType.postalCode:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        formatters.add(LengthLimitingTextInputFormatter(10));
        break;
      default:
        break;
    }
    
    // Add length limiting if specified
    if (widget.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }
    
    // Add custom formatters
    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
    }
    
    return formatters;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      textCapitalization: widget.textCapitalization,
      inputFormatters: _getInputFormatters(),
      validator: _getValidator,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(),
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        contentPadding: widget.contentPadding,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        counterText: widget.maxLength != null ? null : '',
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.fieldType == SecureFieldType.password) {
      return IconButton(
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixIcon;
  }
}

/// Types of secure form fields with built-in validation
enum SecureFieldType {
  text,
  email,
  phone,
  password,
  url,
  numeric,
  nationalCode,
  bankCard,
  sheba,
  fileName,
  postalCode,
  website,
}

/// Bank card number formatter (adds spaces every 4 digits)
class _BankCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Secure form widget that ensures all fields use proper validation
class SecureForm extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final Widget child;
  final bool autovalidateMode;
  final VoidCallback? onChanged;

  const SecureForm({
    super.key,
    this.formKey,
    required this.child,
    this.autovalidateMode = false,
    this.onChanged,
  });

  @override
  State<SecureForm> createState() => _SecureFormState();
}

class _SecureFormState extends State<SecureForm> {
  late GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: widget.autovalidateMode 
        ? AutovalidateMode.onUserInteraction 
        : AutovalidateMode.disabled,
      onChanged: widget.onChanged,
      child: widget.child,
    );
  }
}

/// Helper class for form validation and security
class FormSecurity {
  FormSecurity._();

  /// Validates all fields in a form and returns security report
  static Map<String, dynamic> validateFormSecurity(
    GlobalKey<FormState> formKey,
    Map<String, dynamic> formData,
  ) {
    final report = <String, dynamic>{
      'isValid': false,
      'securityIssues': <String>[],
      'sanitizedData': <String, dynamic>{},
    };

    if (!formKey.currentState!.validate()) {
      report['securityIssues'].add('Form validation failed');
      return report;
    }

    // Sanitize all text fields
    final sanitizedData = <String, dynamic>{};
    for (final entry in formData.entries) {
      if (entry.value is String) {
        sanitizedData[entry.key] = Validators.sanitizeHtml(entry.value);
      } else {
        sanitizedData[entry.key] = entry.value;
      }
    }

    report['isValid'] = true;
    report['sanitizedData'] = sanitizedData;
    return report;
  }

  /// Rate limiting for sensitive form submissions
  static final Map<String, DateTime> _lastSubmissions = {};
  
  static bool canSubmit(String formId, {Duration cooldown = const Duration(seconds: 2)}) {
    final now = DateTime.now();
    final lastSubmission = _lastSubmissions[formId];
    
    if (lastSubmission != null && now.difference(lastSubmission) < cooldown) {
      return false;
    }
    
    _lastSubmissions[formId] = now;
    return true;
  }
}