import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../../core/offline/offline_manager.dart';
import '../../../core/sync/background_sync_service.dart';
import '../../../core/theme/theme_constants.dart';
import '../../../core/widgets/enhanced_loading_indicator.dart';

/// Offline Status Widget with sync controls
class OfflineStatusWidget extends StatefulWidget {
  final bool showDetails;
  final bool showSyncButton;
  final VoidCallback? onSyncPressed;

  const OfflineStatusWidget({
    Key? key,
    this.showDetails = false,
    this.showSyncButton = true,
    this.onSyncPressed,
  }) : super(key: key);

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget>
    with TickerProviderStateMixin {
  
  final OfflineManager _offlineManager = OfflineManager();
  StreamSubscription<OfflineStatus>? _statusSubscription;
  
  late AnimationController _syncAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  OfflineStatus? _currentStatus;
  SyncStatus? _syncStatus;
  bool _isSyncing = false;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToStatus();
    _updateSyncStatus();
    _startPeriodicUpdates();
  }

  /// Initialize animations
  void _initializeAnimations() {
    _syncAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  /// Subscribe to offline status changes
  void _subscribeToStatus() {
    _statusSubscription = _offlineManager.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
        
        // Start pulse animation for offline status
        if (!status.isOnline) {
          _pulseAnimationController.repeat(reverse: true);
        } else {
          _pulseAnimationController.stop();
          _pulseAnimationController.reset();
        }
      }
    });
  }

  /// Update sync status
  Future<void> _updateSyncStatus() async {
    try {
      final status = await _offlineManager.getSyncStatus();
      if (mounted) {
        setState(() {
          _syncStatus = status;
          _isSyncing = status.isActive;
        });
        
        // Control sync animation
        if (status.isActive) {
          _syncAnimationController.repeat();
        } else {
          _syncAnimationController.stop();
          _syncAnimationController.reset();
        }
      }
    } catch (e) {
      debugPrint('[OfflineStatusWidget] Update sync status failed: $e');
    }
  }

  /// Start periodic status updates
  void _startPeriodicUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateSyncStatus();
    });
  }

  /// Handle sync button pressed
  Future<void> _handleSyncPressed() async {
    if (_isSyncing) return;
    
    try {
      setState(() {
        _isSyncing = true;
      });
      
      _syncAnimationController.repeat();
      HapticFeedback.mediumImpact();
      
      final result = await _offlineManager.forceSync();
      
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        
        if (result.isSuccess) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
      // Call custom callback
      widget.onSyncPressed?.call();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _syncAnimationController.stop();
        _syncAnimationController.reset();
      }
      
      // Update status after sync
      await Future.delayed(const Duration(milliseconds: 500));
      _updateSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return const SizedBox.shrink();
    }

    if (widget.showDetails) {
      return _buildDetailedStatus(context);
    } else {
      return _buildCompactStatus(context);
    }
  }

  /// Build compact status indicator
  Widget _buildCompactStatus(BuildContext context) {
    final status = _currentStatus!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: status.isOnline ? 1.0 : _pulseAnimation.value,
                child: Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: _getStatusColor(status),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.showSyncButton && _syncStatus?.pendingCount != null && _syncStatus!.pendingCount > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSyncPressed,
              child: AnimatedBuilder(
                animation: _syncAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _syncAnimationController.value * 2 * 3.14159,
                    child: Icon(
                      Icons.sync,
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build detailed status view
  Widget _buildDetailedStatus(BuildContext context) {
    final status = _currentStatus!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: status.isOnline ? 1.0 : _pulseAnimation.value,
                      child: Icon(
                        _getStatusIcon(status),
                        size: 24,
                        color: _getStatusColor(status),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(status),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusDescription(status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showSyncButton)
                  _buildSyncButton(context),
              ],
            ),
            if (_syncStatus != null) ...[
              const SizedBox(height: 16),
              _buildSyncInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Build sync button
  Widget _buildSyncButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _syncAnimationController,
      builder: (context, child) {
        return IconButton(
          onPressed: _isSyncing ? null : _handleSyncPressed,
          icon: Transform.rotate(
            angle: _syncAnimationController.value * 2 * 3.14159,
            child: Icon(
              Icons.sync,
              color: _isSyncing
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          tooltip: _isSyncing ? 'Syncing...' : 'Force sync',
        );
      },
    );
  }

  /// Build sync information
  Widget _buildSyncInfo(BuildContext context) {
    final syncStatus = _syncStatus!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_sync,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSyncInfoRow(
          context,
          'Pending items',
          syncStatus.pendingCount.toString(),
          syncStatus.pendingCount > 0 ? Colors.orange : Colors.green,
        ),
        if (syncStatus.conflictCount > 0)
          _buildSyncInfoRow(
            context,
            'Conflicts',
            syncStatus.conflictCount.toString(),
            Colors.red,
          ),
        if (syncStatus.lastSyncTime != null)
          _buildSyncInfoRow(
            context,
            'Last sync',
            _formatLastSyncTime(syncStatus.lastSyncTime!),
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }

  /// Build sync info row
  Widget _buildSyncInfoRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(OfflineStatus status) {
    if (status.isOnline) {
      return Colors.green;
    } else {
      switch (status.mode) {
        case OfflineMode.automatic:
          return Colors.orange;
        case OfflineMode.offlineOnly:
          return Colors.blue;
        case OfflineMode.onlineOnly:
          return Colors.red;
      }
    }
  }

  /// Get status icon
  IconData _getStatusIcon(OfflineStatus status) {
    if (status.isOnline) {
      return Icons.cloud_done;
    } else {
      switch (status.mode) {
        case OfflineMode.automatic:
          return Icons.cloud_off;
        case OfflineMode.offlineOnly:
          return Icons.cloud_download;
        case OfflineMode.onlineOnly:
          return Icons.cloud_off;
      }
    }
  }

  /// Get status text
  String _getStatusText(OfflineStatus status) {
    if (status.isOnline) {
      return 'Online';
    } else {
      switch (status.mode) {
        case OfflineMode.automatic:
          return 'Offline';
        case OfflineMode.offlineOnly:
          return 'Offline Mode';
        case OfflineMode.onlineOnly:
          return 'No Connection';
      }
    }
  }

  /// Get status description
  String _getStatusDescription(OfflineStatus status) {
    if (status.isOnline) {
      return 'Connected to server';
    } else {
      switch (status.mode) {
        case OfflineMode.automatic:
          return 'Working offline, will sync when connected';
        case OfflineMode.offlineOnly:
          return 'Offline mode enabled';
        case OfflineMode.onlineOnly:
          return 'Connection required for this mode';
      }
    }
  }

  /// Format last sync time
  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statusUpdateTimer?.cancel();
    _syncAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
}

/// Offline Settings Dialog
class OfflineSettingsDialog extends StatefulWidget {
  const OfflineSettingsDialog({Key? key}) : super(key: key);

  @override
  State<OfflineSettingsDialog> createState() => _OfflineSettingsDialogState();
}

class _OfflineSettingsDialogState extends State<OfflineSettingsDialog> {
  final OfflineManager _offlineManager = OfflineManager();
  
  OfflineMode _selectedMode = OfflineMode.automatic;
  String _selectedConflictResolution = 'server_wins';
  bool _isLoading = true;
  OfflineStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load current settings
  Future<void> _loadSettings() async {
    try {
      _selectedMode = _offlineManager.currentMode;
      _statistics = await _offlineManager.getOfflineStatistics();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    try {
      await _offlineManager.setOfflineMode(_selectedMode);
      await _offlineManager.setConflictResolutionStrategy(_selectedConflictResolution);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Offline Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
          ? const Center(
              child: EnhancedLoadingIndicator(
                message: 'Loading settings...',
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSelection(),
                const SizedBox(height: 24),
                _buildConflictResolutionSelection(),
                const SizedBox(height: 24),
                _buildStatistics(),
              ],
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Build mode selection
  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline Mode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<OfflineMode>(
          title: const Text('Automatic'),
          subtitle: const Text('Switch automatically based on connection'),
          value: OfflineMode.automatic,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        RadioListTile<OfflineMode>(
          title: const Text('Offline Only'),
          subtitle: const Text('Always work offline'),
          value: OfflineMode.offlineOnly,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        RadioListTile<OfflineMode>(
          title: const Text('Online Only'),
          subtitle: const Text('Require internet connection'),
          value: OfflineMode.onlineOnly,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
      ],
    );
  }

  /// Build conflict resolution selection
  Widget _buildConflictResolutionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflict Resolution',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedConflictResolution,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Strategy',
          ),
          items: const [
            DropdownMenuItem(
              value: 'server_wins',
              child: Text('Server Wins'),
            ),
            DropdownMenuItem(
              value: 'client_wins',
              child: Text('Local Wins'),
            ),
            DropdownMenuItem(
              value: 'merge',
              child: Text('Merge Data'),
            ),
            DropdownMenuItem(
              value: 'manual',
              child: Text('Manual Resolution'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedConflictResolution = value!;
            });
          },
        ),
      ],
    );
  }

  /// Build statistics
  Widget _buildStatistics() {
    if (_statistics == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Devices', _statistics!.deviceCount.toString()),
        _buildStatRow('Energy Data', _statistics!.energyDataCount.toString()),
        _buildStatRow('Pending Sync', _statistics!.pendingSyncCount.toString()),
        if (_statistics!.conflictCount > 0)
          _buildStatRow('Conflicts', _statistics!.conflictCount.toString()),
      ],
    );
  }

  /// Build statistics row
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}