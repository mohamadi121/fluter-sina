import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceL, vertical: AppDimens.spaceM),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: textTheme.headlineSmall),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: textTheme.labelLarge?.copyWith(color: scheme.primary)),
            ),
        ],
      ),
    );
  }
}
