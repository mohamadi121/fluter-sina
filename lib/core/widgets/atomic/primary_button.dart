import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool destructive;
  final EdgeInsets? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.destructive = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;
    final bg = destructive ? scheme.error : scheme.primary;
    final fg = destructive ? scheme.onError : scheme.onPrimary;
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: disabled ? scheme.surfaceVariant : bg,
        foregroundColor: disabled ? scheme.onSurfaceVariant : fg,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppDimens.spaceXL, vertical: AppDimens.spaceM),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusM)),
      ),
      onPressed: disabled ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(fg)),
            ),
            const SizedBox(width: 12),
          ] else if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
