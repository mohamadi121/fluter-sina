import 'package:flutter/material.dart';
import '../responsive/responsive_design.dart';
import '../theme/app_theme.dart';

/// Enhanced Button Component with Material Design 3 and responsiveness
class AsoudButton extends StatelessWidget {
  const AsoudButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.onLongPress,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;
    
    // Get responsive dimensions
    final buttonHeight = _getButtonHeight(context);
    final fontSize = _getFontSize(context);
    final borderRadius = ResponsiveDesign.getAdaptiveBorderRadius(context, baseRadius: 12);
    final iconSize = ResponsiveDesign.getAdaptiveIconSize(context, baseSize: 20);
    
    Widget buttonChild = _buildButtonContent(
      context,
      fontSize: fontSize,
      iconSize: iconSize,
    );

    if (isLoading) {
      buttonChild = _buildLoadingContent(context, iconSize: iconSize);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton(
          context,
          child: buttonChild,
          height: buttonHeight,
          borderRadius: borderRadius,
          isEnabled: isButtonEnabled,
        );
      case ButtonVariant.secondary:
        return _buildOutlinedButton(
          context,
          child: buttonChild,
          height: buttonHeight,
          borderRadius: borderRadius,
          isEnabled: isButtonEnabled,
        );
      case ButtonVariant.tertiary:
        return _buildTextButton(
          context,
          child: buttonChild,
          height: buttonHeight,
          borderRadius: borderRadius,
          isEnabled: isButtonEnabled,
        );
      case ButtonVariant.destructive:
        return _buildDestructiveButton(
          context,
          child: buttonChild,
          height: buttonHeight,
          borderRadius: borderRadius,
          isEnabled: isButtonEnabled,
        );
    }
  }

  Widget _buildElevatedButton(
    BuildContext context, {
    required Widget child,
    required double height,
    required double borderRadius,
    required bool isEnabled,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: ResponsiveDesign.getCardElevation(context),
        ),
        child: child,
      ),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context, {
    required Widget child,
    required double height,
    required double borderRadius,
    required bool isEnabled,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        onLongPress: onLongPress,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context, {
    required Widget child,
    required double height,
    required double borderRadius,
    required bool isEnabled,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        onLongPress: onLongPress,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDestructiveButton(
    BuildContext context, {
    required Widget child,
    required double height,
    required double borderRadius,
    required bool isEnabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildButtonContent(
    BuildContext context, {
    required double fontSize,
    required double iconSize,
  }) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          SizedBox(width: theme.spacingS),
          Text(
            text,
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      );
    }
    
    return Text(
      text,
      style: TextStyle(fontSize: fontSize),
    );
  }

  Widget _buildLoadingContent(
    BuildContext context, {
    required double iconSize,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              variant == ButtonVariant.primary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: Theme.of(context).spacingS),
        Text(
          'در حال بارگذاری...',
          style: TextStyle(fontSize: _getFontSize(context)),
        ),
      ],
    );
  }

  double _getButtonHeight(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 32,
          tablet: 36,
          desktop: 40,
        );
      case ButtonSize.medium:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 44,
          tablet: 48,
          desktop: 52,
        );
      case ButtonSize.large:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 56,
          tablet: 60,
          desktop: 64,
        );
    }
  }

  double _getFontSize(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return ResponsiveDesign.getAdaptiveFontSize(context, baseSize: 12);
      case ButtonSize.medium:
        return ResponsiveDesign.getAdaptiveFontSize(context, baseSize: 14);
      case ButtonSize.large:
        return ResponsiveDesign.getAdaptiveFontSize(context, baseSize: 16);
    }
  }
}

/// Enhanced Card Component with Material Design 3
class AsoudCard extends StatelessWidget {
  const AsoudCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isClickable = false,
  });

  final Widget child;
  final CardVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isClickable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = ResponsiveDesign.getAdaptiveBorderRadius(context);
    final cardPadding = padding ?? ResponsiveDesign.getAdaptivePadding(context);
    final cardMargin = margin ?? ResponsiveDesign.getAdaptiveMargin(context);

    Widget cardChild = Padding(
      padding: cardPadding,
      child: child,
    );

    if (isClickable || onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardChild,
      );
    }

    switch (variant) {
      case CardVariant.elevated:
        return Container(
          margin: cardMargin,
          child: Card(
            elevation: ResponsiveDesign.getCardElevation(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: cardChild,
          ),
        );
      case CardVariant.filled:
        return Container(
          margin: cardMargin,
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: cardChild,
          ),
        );
      case CardVariant.outlined:
        return Container(
          margin: cardMargin,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: cardChild,
          ),
        );
    }
  }
}

/// Enhanced Text Field Component
class AsoudTextField extends StatelessWidget {
  const AsoudTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.isEnabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool isEnabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = ResponsiveDesign.getAdaptiveBorderRadius(context, baseRadius: 12);
    
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      obscureText: isPassword,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecorationTheme(
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        contentPadding: ResponsiveDesign.getAdaptivePadding(context),
      ).copyWith(),
    );
  }
}

/// Enhanced Loading Widget
class AsoudLoading extends StatelessWidget {
  const AsoudLoading({
    super.key,
    this.size = LoadingSize.medium,
    this.message,
    this.color,
  });

  final LoadingSize size;
  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;
    final indicatorSize = _getIndicatorSize(context);
    
    Widget indicator = SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(height: theme.spacingM),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }

  double _getIndicatorSize(BuildContext context) {
    switch (size) {
      case LoadingSize.small:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        );
      case LoadingSize.medium:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 24,
          tablet: 28,
          desktop: 32,
        );
      case LoadingSize.large:
        return ResponsiveDesign.responsiveValue(
          context: context,
          mobile: 32,
          tablet: 36,
          desktop: 40,
        );
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
    }
  }
}

// Enums for component variants
enum ButtonVariant { primary, secondary, tertiary, destructive }
enum ButtonSize { small, medium, large }
enum CardVariant { elevated, filled, outlined }
enum LoadingSize { small, medium, large }