import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';
import 'package:asoud/core/network/app_error.dart';

class ErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.error, this.onRetry});

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
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: AppDimens.spaceL),
            Text(error.message, style: textTheme.titleLarge, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.spaceXL),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
            ],
          ],
        ),
      ),
    );
  }
}
