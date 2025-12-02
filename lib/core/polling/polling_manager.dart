import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Manages polling lifecycle across the app
///
/// Ensures only the active screen's polling is running.
/// Other screens pause their polling to save battery and bandwidth.
///
/// PAGE-FOCUSED POLLING RULE:
/// --------------------------
/// - Only pollers for the ACTIVE FEATURE can run
/// - When switching features, all pollers from the OLD feature are PAUSED
/// - ALL pollers for the ACTIVE feature run simultaneously
///   (e.g., multiple category products can poll at once when on Categories tab)
/// - Pollers should NOT start their timers immediately on registration
/// - Instead, they wait for onResume callback before starting the timer
///
/// Usage:
/// ```dart
/// // In notifier - DO NOT start timer before registration!
/// void _registerForPolling() {
///   // Only registers, does NOT start polling
///   PollingManager.instance.registerPoller(
///     featureName: 'product_detail',
///     resourceId: variantId,
///     onResume: _startPollingTimer,  // Timer starts ONLY here
///     onPause: _stopPollingTimer,
///   );
/// }
/// ```
class PollingManager {
  static final PollingManager _instance = PollingManager._internal();

  factory PollingManager() {
    return _instance;
  }

  PollingManager._internal();

  static PollingManager get instance => _instance;

  /// Map of registered pollers: featureName:resourceId → poller info
  final Map<String, _PollerInfo> _pollers = {};

  /// Set of currently active poller keys (featureName:resourceId)
  /// Multiple pollers can be active for the same feature
  final Set<String> _activePollerKeys = {};

  /// Currently active feature (e.g., 'category_products', 'cart', 'product_detail')
  /// Only pollers matching this feature will be allowed to run
  String? _activeFeature;

  /// Listeners for poller state changes
  final List<VoidCallback> _listeners = [];

  /// Register a poller
  ///
  /// IMPORTANT: This does NOT start polling immediately!
  /// The poller will only start when:
  /// 1. Its feature is currently active (set via setActiveFeature or activatePoller)
  /// 2. And onResume callback is invoked
  ///
  /// Parameters:
  /// - featureName: Name of the feature (e.g., 'product_detail', 'category', 'cart')
  /// - resourceId: Unique identifier for the resource (e.g., product ID, category ID)
  /// - onResume: Callback to start polling timer (called ONLY when this poller is activated)
  /// - onPause: Callback to stop polling timer (called when another poller/feature is activated)
  void registerPoller({
    required String featureName,
    required String resourceId,
    required VoidCallback onResume,
    required VoidCallback onPause,
  }) {
    final key = '$featureName:$resourceId';

    _pollers[key] = _PollerInfo(
      featureName: featureName,
      resourceId: resourceId,
      onResume: onResume,
      onPause: onPause,
    );

    developer.log(
      'Poller registered: $key (activeFeature: $_activeFeature)',
      name: 'PollingManager',
      level: 500,
    );

    // If this poller's feature is currently active, start it immediately
    if (_activeFeature == featureName) {
      developer.log(
        'Auto-starting poller $key (feature $featureName is active)',
        name: 'PollingManager',
        level: 700,
      );
      _startPoller(key);
    }
  }

  /// Start a single poller (add to active set and call onResume)
  void _startPoller(String key) {
    final poller = _pollers[key];
    if (poller == null) return;

    if (!_activePollerKeys.contains(key)) {
      _activePollerKeys.add(key);
      poller.onResume();
      developer.log('Poller started: $key', name: 'PollingManager', level: 700);
    }
  }

  /// Stop a single poller (remove from active set and call onPause)
  void _stopPoller(String key) {
    final poller = _pollers[key];
    if (poller == null) return;

    if (_activePollerKeys.contains(key)) {
      _activePollerKeys.remove(key);
      poller.onPause();
      developer.log('Poller stopped: $key', name: 'PollingManager', level: 700);
    }
  }

  /// Set the currently active feature
  ///
  /// This pauses all pollers from other features and starts
  /// ALL pollers for the new feature.
  ///
  /// Example: When user switches to Cart tab, call setActiveFeature('cart')
  /// This will pause category/product_detail pollers and start cart pollers.
  void setActiveFeature(String featureName) {
    if (_activeFeature == featureName) {
      developer.log(
        'Feature already active: $featureName',
        name: 'PollingManager',
        level: 500,
      );
      return;
    }

    developer.log(
      'Setting active feature: $featureName (was: $_activeFeature)',
      name: 'PollingManager',
      level: 800,
    );

    // Pause all pollers from the previous feature
    _pauseAllPollersForFeature(_activeFeature);

    _activeFeature = featureName;

    // Start ALL pollers for the new active feature
    _startAllPollersForFeature(featureName);

    _notifyListeners();
  }

  /// Start all pollers for a specific feature
  void _startAllPollersForFeature(String featureName) {
    int startedCount = 0;
    for (final entry in _pollers.entries) {
      if (entry.value.featureName == featureName) {
        _startPoller(entry.key);
        startedCount++;
      }
    }
    developer.log(
      'Started $startedCount pollers for feature: $featureName',
      name: 'PollingManager',
      level: 800,
    );
  }

  /// Pause all pollers for a specific feature
  void _pauseAllPollersForFeature(String? featureName) {
    if (featureName == null) return;

    int pausedCount = 0;
    for (final entry in _pollers.entries) {
      if (entry.value.featureName == featureName) {
        _stopPoller(entry.key);
        pausedCount++;
      }
    }
    developer.log(
      'Paused $pausedCount pollers for feature: $featureName',
      name: 'PollingManager',
      level: 800,
    );
  }

  /// Get the currently active feature
  String? get activeFeature => _activeFeature;

  /// Unregister a poller
  void unregisterPoller({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';

    // Stop the poller if it's running
    _stopPoller(key);

    _pollers.remove(key);

    developer.log(
      'Poller unregistered: $key',
      name: 'PollingManager',
      level: 500,
    );
  }

  /// Activate a poller (user navigated to this screen)
  ///
  /// This also sets the active feature to match the poller's feature,
  /// which will pause all pollers from other features and start
  /// all pollers for this feature.
  void activatePoller({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';

    // If switching to a different feature, change the active feature
    if (_activeFeature != featureName) {
      setActiveFeature(featureName);
    } else {
      // Same feature - just make sure this poller is started
      _startPoller(key);
    }
  }

  /// Pause the currently active feature's pollers
  void pauseActive() {
    if (_activeFeature != null) {
      _pauseAllPollersForFeature(_activeFeature);
    }
  }

  /// Pause all active polling (e.g., when app goes to background)
  void pauseAllPolling() {
    developer.log(
      'Pausing all polling (${_activePollerKeys.length} active)',
      name: 'PollingManager',
      level: 800,
    );

    // Stop all active pollers
    for (final key in _activePollerKeys.toList()) {
      final poller = _pollers[key];
      if (poller != null) {
        poller.onPause();
      }
    }
    _activePollerKeys.clear();
    _notifyListeners();
  }

  /// Resume polling for the active feature (e.g., when app comes to foreground)
  void resumeActiveFeaturePolling() {
    if (_activeFeature == null) {
      developer.log(
        'No active feature to resume',
        name: 'PollingManager',
        level: 500,
      );
      return;
    }

    developer.log(
      'Resuming polling for feature: $_activeFeature',
      name: 'PollingManager',
      level: 800,
    );

    // Resume ALL pollers for the active feature
    _startAllPollersForFeature(_activeFeature!);
    _notifyListeners();
  }

  /// Get all currently active poller keys
  Set<String> get activePollerKeys => Set.unmodifiable(_activePollerKeys);

  /// Check if a specific poller is active
  bool isPollerActive({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';
    return _activePollerKeys.contains(key);
  }

  /// Listen to poller state changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of state changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Debug: Get all registered pollers
  List<String> get registeredPollers => _pollers.keys.toList();

  /// Debug: Print current state
  void debugPrintState() {
    developer.log(
      'PollingManager State:\n'
      'Active Feature: $_activeFeature\n'
      'Active Pollers: ${_activePollerKeys.join(", ")}\n'
      'Registered: ${_pollers.keys.join(", ")}\n'
      'Total Count: ${_pollers.length}',
      name: 'PollingManager',
    );
  }
}

/// Internal: Information about a registered poller
class _PollerInfo {
  _PollerInfo({
    required this.featureName,
    required this.resourceId,
    required this.onResume,
    required this.onPause,
  });

  final String featureName;
  final String resourceId;
  final VoidCallback onResume;
  final VoidCallback onPause;
}
