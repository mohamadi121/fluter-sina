import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessible button with proper semantics and minimum touch target
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonStyle? style;
  final String? semanticLabel;
  final String? tooltip;
  final bool autofocus;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.semanticLabel,
    this.tooltip,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(label),
            style: style,
            autofocus: autofocus,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: style,
            autofocus: autofocus,
            child: Text(label),
          );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: button,
    );
  }
}

/// Accessible text field with proper semantics
class AccessibleTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final String? semanticLabel;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final int? maxLength;

  const AccessibleTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.semanticLabel,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label ?? hint,
      textField: true,
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }
}

/// Accessible card with proper touch target and semantics
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
    this.margin,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      elevation: elevation,
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Semantics(
        label: semanticLabel,
        button: true,
        child: card,
      );
    }

    return card;
  }
}

/// Loading indicator with accessibility announcement
class AccessibleLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const AccessibleLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'در حال بارگذاری',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: const CircularProgressIndicator(),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget with accessibility
class AccessibleEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccessibleEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title${subtitle != null ? '. $subtitle' : ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(height: 24),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                AccessibleButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state widget with accessibility
class AccessibleErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onRetry;

  const AccessibleErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'خطا: $title${subtitle != null ? '. $subtitle' : ''}',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onRetry != null) ...[
                const SizedBox(height: 24),
                AccessibleButton(
                  label: actionLabel!,
                  onPressed: onRetry,
                  semanticLabel: 'تلاش مجدد: $actionLabel',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus traversal order helper
class AccessibleFocusTraversal extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;

  const AccessibleFocusTraversal({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: direction == Axis.vertical
          ? ReadingOrderTraversalPolicy()
          : OrderedTraversalPolicy(),
      child: direction == Axis.vertical
          ? Column(children: children)
          : Row(children: children),
    );
  }
}
