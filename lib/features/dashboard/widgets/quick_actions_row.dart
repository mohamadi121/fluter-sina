import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/smart_home_dashboard_screen.dart';

/// Quick Actions Row Widget
class QuickActionsRow extends StatelessWidget {
  final Function(QuickActionType) onActionTap;

  const QuickActionsRow({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.lightbulb,
                  label: 'Lights',
                  color: Colors.amber,
                  onTap: () => onActionTap(QuickActionType.allLights),
                ),
                _QuickActionButton(
                  icon: Icons.security,
                  label: 'Security',
                  color: Colors.red,
                  onTap: () => onActionTap(QuickActionType.security),
                ),
                _QuickActionButton(
                  icon: Icons.thermostat,
                  label: 'Climate',
                  color: Colors.blue,
                  onTap: () => onActionTap(QuickActionType.climate),
                ),
                _QuickActionButton(
                  icon: Icons.scene,
                  label: 'Scenes',
                  color: Colors.purple,
                  onTap: () => onActionTap(QuickActionType.scenes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}