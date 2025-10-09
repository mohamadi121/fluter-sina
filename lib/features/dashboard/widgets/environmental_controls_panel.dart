import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/smart_home_dashboard_screen.dart';

/// Environmental Controls Panel Widget
class EnvironmentalControlsPanel extends StatelessWidget {
  final EnvironmentalData? environmentalData;
  final Function(EnvironmentalControlType, double)? onControlChange;

  const EnvironmentalControlsPanel({
    super.key,
    this.environmentalData,
    this.onControlChange,
  });

  @override
  Widget build(BuildContext context) {
    if (environmentalData == null) {
      return _buildLoadingCard();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Controls',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEnvironmentalGrid(),
            const SizedBox(height: 16),
            _buildControlSliders(),
          ],
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

  Widget _buildEnvironmentalGrid() {
    return Row(
      children: [
        Expanded(
          child: _EnvironmentalMetric(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: '${environmentalData!.temperature.toStringAsFixed(1)}°C',
            color: _getTemperatureColor(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EnvironmentalMetric(
            icon: Icons.water_drop,
            label: 'Humidity',
            value: '${environmentalData!.humidity.toStringAsFixed(0)}%',
            color: _getHumidityColor(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EnvironmentalMetric(
            icon: Icons.air,
            label: 'Air Quality',
            value: '${environmentalData!.airQuality}',
            color: _getAirQualityColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlSliders() {
    return Column(
      children: [
        _ControlSlider(
          label: 'Temperature',
          icon: Icons.thermostat,
          value: environmentalData!.temperature,
          min: 16.0,
          max: 30.0,
          divisions: 14,
          unit: '°C',
          color: Colors.orange,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onControlChange?.call(EnvironmentalControlType.temperature, value);
          },
        ),
        const SizedBox(height: 12),
        _ControlSlider(
          label: 'Lighting',
          icon: Icons.lightbulb,
          value: environmentalData!.lightLevel.toDouble(),
          min: 0.0,
          max: 100.0,
          divisions: 10,
          unit: '%',
          color: Colors.amber,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onControlChange?.call(EnvironmentalControlType.lighting, value);
          },
        ),
      ],
    );
  }

  Color _getTemperatureColor() {
    final temp = environmentalData!.temperature;
    if (temp < 18 || temp > 26) return Colors.orange;
    return Colors.green;
  }

  Color _getHumidityColor() {
    final humidity = environmentalData!.humidity;
    if (humidity < 30 || humidity > 60) return Colors.orange;
    return Colors.green;
  }

  Color _getAirQualityColor() {
    final quality = environmentalData!.airQuality;
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _EnvironmentalMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _EnvironmentalMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleSmall.copyWith(
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

class _ControlSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final Color color;
  final ValueChanged<double>? onChanged;

  const _ControlSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: AppTheme.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}