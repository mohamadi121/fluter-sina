import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/router/route_guards.dart';

/// Smart Home App Shell with Navigation
class SmartHomeShell extends StatefulWidget {
  final Widget child;

  const SmartHomeShell({
    super.key,
    required this.child,
  });

  @override
  State<SmartHomeShell> createState() => _SmartHomeShellState();
}

class _SmartHomeShellState extends State<SmartHomeShell>
    with TickerProviderStateMixin {
  
  int _currentIndex = 0;
  late AnimationController _navigationAnimationController;
  late Animation<double> _navigationAnimation;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.devices_outlined),
      selectedIcon: Icon(Icons.devices),
      label: 'Devices',
    ),
    const NavigationDestination(
      icon: Icon(Icons.thermostat_outlined),
      selectedIcon: Icon(Icons.thermostat),
      label: 'Environment',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Performance',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _navigationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _navigationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navigationAnimationController,
      curve: Curves.easeInOut,
    ));

    _navigationAnimationController.forward();
  }

  @override
  void dispose() {
    _navigationAnimationController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) async {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();

    // Route mapping
    String route;
    switch (index) {
      case 0:
        route = AppRoutes.dashboard;
        break;
      case 1:
        route = AppRoutes.deviceManagement;
        break;
      case 2:
        route = AppRoutes.environmentalControl;
        break;
      case 3:
        route = AppRoutes.performanceDashboard;
        break;
      default:
        route = AppRoutes.dashboard;
    }

    // Check access
    final canAccess = await RouteGuards.canAccess(route);
    if (!canAccess) {
      _showAccessDeniedSnackBar();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Navigate
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _showAccessDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Access denied to this section'),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedBuilder(
      animation: _navigationAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _navigationAnimation.value) * 100,
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations,
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
            elevation: 8,
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _navigationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _navigationAnimation.value,
          child: FloatingActionButton(
            onPressed: _onQuickAction,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.add_home_outlined),
          ),
        );
      },
    );
  }

  void _onQuickAction() {
    HapticFeedback.mediumImpact();
    _showQuickActionsBottomSheet();
  }

  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsBottomSheet(),
    );
  }
}

/// Quick Actions Bottom Sheet
class QuickActionsBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _QuickActionTile(
                icon: Icons.lightbulb_outline,
                label: 'Lights',
                onTap: () => _handleQuickAction('lights'),
              ),
              _QuickActionTile(
                icon: Icons.thermostat_outlined,
                label: 'Climate',
                onTap: () => _handleQuickAction('climate'),
              ),
              _QuickActionTile(
                icon: Icons.security_outlined,
                label: 'Security',
                onTap: () => _handleQuickAction('security'),
              ),
              _QuickActionTile(
                icon: Icons.music_note_outlined,
                label: 'Music',
                onTap: () => _handleQuickAction('music'),
              ),
              _QuickActionTile(
                icon: Icons.schedule_outlined,
                label: 'Scenes',
                onTap: () => _handleQuickAction('scenes'),
              ),
              _QuickActionTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _handleQuickAction('settings'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleQuickAction(String action) {
    // Handle quick actions
    debugPrint('Quick action: $action');
  }
}

/// Quick Action Tile
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
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
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.primaryColor,
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