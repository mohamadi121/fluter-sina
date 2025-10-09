import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';

/// Smart Home Error Page
class SmartHomeErrorPage extends StatelessWidget {
  final Exception? error;
  final String routeName;

  const SmartHomeErrorPage({
    super.key,
    this.error,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildErrorIcon(),
              const SizedBox(height: 24),
              _buildErrorTitle(),
              const SizedBox(height: 16),
              _buildErrorMessage(),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: Colors.red[200]!,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.error_outline,
        size: 64,
        color: Colors.red[600],
      ),
    );
  }

  Widget _buildErrorTitle() {
    return Text(
      'Something went wrong',
      style: AppTheme.headlineMedium.copyWith(
        color: Colors.red[700],
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      children: [
        Text(
          'We encountered an error while trying to load the page.',
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (routeName.isNotEmpty)
          Text(
            'Route: $routeName',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              error.toString(),
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _goHome(context),
            icon: const Icon(Icons.home),
            label: const Text('Go to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildReportButton(context),
      ],
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _reportError(context),
      icon: const Icon(Icons.bug_report, size: 18),
      label: const Text('Report this error'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey[600],
      ),
    );
  }

  void _goHome(BuildContext context) {
    context.go(AppRoutes.dashboard);
  }

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  void _reportError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Error'),
        content: const Text(
          'Thank you for helping us improve the app. '
          'Error details have been logged and will be reviewed by our team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Error Widget for specific error types
class SmartHomeErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const SmartHomeErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.headlineSmall.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRetry != null || onCancel != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCancel != null) ...[
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onRetry != null)
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Network Error Widget
class NetworkErrorWidget extends SmartHomeErrorWidget {
  const NetworkErrorWidget({
    super.key,
    super.onRetry,
    super.onCancel,
  }) : super(
          title: 'Network Error',
          message: 'Please check your internet connection and try again.',
          icon: Icons.wifi_off,
        );
}

/// Device Not Found Error Widget
class DeviceNotFoundErrorWidget extends SmartHomeErrorWidget {
  const DeviceNotFoundErrorWidget({
    super.key,
    super.onRetry,
    super.onCancel,
  }) : super(
          title: 'Device Not Found',
          message: 'The requested device could not be found or is offline.',
          icon: Icons.device_unknown,
        );
}

/// Permission Denied Error Widget
class PermissionDeniedErrorWidget extends SmartHomeErrorWidget {
  const PermissionDeniedErrorWidget({
    super.key,
    super.onRetry,
    super.onCancel,
  }) : super(
          title: 'Permission Denied',
          message: 'You don\'t have permission to access this feature.',
          icon: Icons.lock,
        );
}