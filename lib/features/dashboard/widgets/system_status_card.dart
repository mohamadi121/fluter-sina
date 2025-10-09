import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/smart_home_dashboard_screen.dart';

/// System Status Card Widget
class SystemStatusCard extends StatelessWidget {
  final SystemHealth? systemHealth;
  final VoidCallback? onTap;

  const SystemStatusCard({
    super.key,
    this.systemHealth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (systemHealth == null) {
      return _buildLoadingCard();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Status',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildHealthIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildHealthIndicator() {
    final health = systemHealth!.overallHealth;
    Color color;
    IconData icon;
    
    if (health >= 80) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (health >= 60) {
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      color = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$health%',
            style: AppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatusItem(
            label: 'Network',
            value: _getNetworkStatusText(),
            color: _getNetworkStatusColor(),
            icon: Icons.wifi,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusItem(
            label: 'Memory',
            value: '${systemHealth!.memoryUsage.toStringAsFixed(0)} MB',
            color: _getMemoryStatusColor(),
            icon: Icons.memory,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusItem(
            label: 'Devices',
            value: '${systemHealth!.connectedDevices}/${systemHealth!.totalDevices}',
            color: _getDeviceStatusColor(),
            icon: Icons.devices,
          ),
        ),
      ],
    );
  }

  String _getNetworkStatusText() {
    switch (systemHealth!.networkStatus) {
      case NetworkStatus.excellent:
        return 'Excellent';
      case NetworkStatus.good:
        return 'Good';
      case NetworkStatus.fair:
        return 'Fair';
      case NetworkStatus.poor:
        return 'Poor';
      case NetworkStatus.offline:
        return 'Offline';
    }
  }

  Color _getNetworkStatusColor() {
    switch (systemHealth!.networkStatus) {
      case NetworkStatus.excellent:
      case NetworkStatus.good:
        return Colors.green;
      case NetworkStatus.fair:
        return Colors.orange;
      case NetworkStatus.poor:
      case NetworkStatus.offline:
        return Colors.red;
    }
  }

  Color _getMemoryStatusColor() {
    final memory = systemHealth!.memoryUsage;
    if (memory < 100) return Colors.green;
    if (memory < 150) return Colors.orange;
    return Colors.red;
  }

  Color _getDeviceStatusColor() {
    final connected = systemHealth!.connectedDevices;
    final total = systemHealth!.totalDevices;
    final ratio = connected / total;
    
    if (ratio > 0.8) return Colors.green;
    if (ratio > 0.5) return Colors.orange;
    return Colors.red;
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}