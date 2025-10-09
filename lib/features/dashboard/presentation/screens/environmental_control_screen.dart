import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/websocket_service.dart';

/// Environmental Control Screen
/// Controls temperature, humidity, lighting, and air quality
class EnvironmentalControlScreen extends StatefulWidget {
  const EnvironmentalControlScreen({super.key});

  @override
  State<EnvironmentalControlScreen> createState() => _EnvironmentalControlScreenState();
}

class _EnvironmentalControlScreenState extends State<EnvironmentalControlScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late WebSocketService _webSocketService;
  
  // Environmental data
  double _temperature = 22.5;
  double _humidity = 45.0;
  double _airQuality = 85.0;
  double _lightIntensity = 70.0;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _webSocketService = ServiceLocator.get<WebSocketService>();
    _loadEnvironmentalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnvironmentalData() async {
    setState(() => _isLoading = true);
    
    // Simulate loading environmental data
    await Future.delayed(const Duration(milliseconds: 800));
    
    // In real app, this would come from WebSocket or API
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Environmental Control'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: 'Temperature'),
            Tab(icon: Icon(Icons.water_drop), text: 'Humidity'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Lighting'),
            Tab(icon: Icon(Icons.air), text: 'Air Quality'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemperatureControl(),
                _buildHumidityControl(),
                _buildLightingControl(),
                _buildAirQualityControl(),
              ],
            ),
    );
  }

  Widget _buildTemperatureControl() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.thermostat, size: 32, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        '${_temperature.toStringAsFixed(1)}°C',
                        style: AppTheme.displaySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Target Temperature',
                    style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _temperature,
                    min: 16.0,
                    max: 32.0,
                    divisions: 32,
                    activeColor: AppTheme.primaryColor,
                    label: '${_temperature.toStringAsFixed(1)}°C',
                    onChanged: (value) {
                      setState(() => _temperature = value);
                      _updateTemperature(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetButton('16°C', 16.0),
                      _buildPresetButton('20°C', 20.0),
                      _buildPresetButton('24°C', 24.0),
                      _buildPresetButton('28°C', 28.0),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRoomTemperatures(),
        ],
      ),
    );
  }

  Widget _buildHumidityControl() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop, size: 32, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        '${_humidity.toStringAsFixed(0)}%',
                        style: AppTheme.displaySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Target Humidity',
                    style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _humidity,
                    min: 30.0,
                    max: 70.0,
                    divisions: 40,
                    activeColor: Colors.blue,
                    label: '${_humidity.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() => _humidity = value);
                      _updateHumidity(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingControl() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, size: 32, color: Colors.amber),
                      const SizedBox(width: 12),
                      Text(
                        '${_lightIntensity.toStringAsFixed(0)}%',
                        style: AppTheme.displaySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Light Intensity',
                    style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _lightIntensity,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    activeColor: Colors.amber,
                    label: '${_lightIntensity.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() => _lightIntensity = value);
                      _updateLighting(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityControl() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.air, size: 32, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '${_airQuality.toStringAsFixed(0)}%',
                        style: AppTheme.displaySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Air Quality Index',
                    style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _airQuality / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _airQuality > 80 ? Colors.green :
                      _airQuality > 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, double value) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _temperature = value);
        _updateTemperature(value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _buildRoomTemperatures() {
    final rooms = [
      {'name': 'Living Room', 'temp': 23.2, 'icon': Icons.weekend},
      {'name': 'Bedroom', 'temp': 21.8, 'icon': Icons.bed},
      {'name': 'Kitchen', 'temp': 24.1, 'icon': Icons.kitchen},
      {'name': 'Bathroom', 'temp': 22.5, 'icon': Icons.bathtub},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Temperatures',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rooms.map((room) => ListTile(
              leading: Icon(room['icon'] as IconData, color: AppTheme.primaryColor),
              title: Text(room['name'] as String),
              trailing: Text(
                '${(room['temp'] as double).toStringAsFixed(1)}°C',
                style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _updateTemperature(double value) {
    // Send WebSocket command to update temperature
    _webSocketService.sendMessage({
      'type': 'environmental_control',
      'action': 'set_temperature',
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _updateHumidity(double value) {
    _webSocketService.sendMessage({
      'type': 'environmental_control',
      'action': 'set_humidity',
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _updateLighting(double value) {
    _webSocketService.sendMessage({
      'type': 'environmental_control',
      'action': 'set_lighting',
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}