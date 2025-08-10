import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

class EmptyView extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({super.key, required this.title, this.description, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: AppDimens.spaceL),
            Text(title, style: textTheme.titleLarge),
            if (description != null) ...[
              const SizedBox(height: AppDimens.spaceS),
              Text(description!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimens.spaceXL),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ]
          ],
        ),
      ),
    );
  }
}
