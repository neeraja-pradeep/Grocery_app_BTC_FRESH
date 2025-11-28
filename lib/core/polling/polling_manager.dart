import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Manages polling lifecycle across the app
///
/// Ensures only the active screen's polling is running.
/// Other screens pause their polling to save battery and bandwidth.
///
/// Usage:
/// ```dart
/// // In notifier
/// PollingManager.instance.registerPoller(
///   featureName: 'product_detail',
///   resourceId: variantId,
///   onResume: _startPolling,
///   onPause: _stopPolling,
/// );
/// ```
class PollingManager {
  static final PollingManager _instance = PollingManager._internal();

  factory PollingManager() {
    return _instance;
  }

  PollingManager._internal();

  static PollingManager get instance => _instance;

  /// Map of active pollers: featureName:resourceId → poller info
  final Map<String, _PollerInfo> _pollers = {};

  /// Currently active poller (only one should be polling at a time)
  String? _activePollerKey;

  /// Listeners for poller state changes
  final List<VoidCallback> _listeners = [];

  /// Register a poller
  ///
  /// Parameters:
  /// - featureName: Name of the feature (e.g., 'product_detail', 'category')
  /// - resourceId: Unique identifier for the resource (e.g., product ID)
  /// - onResume: Callback to start polling
  /// - onPause: Callback to stop polling
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
      'Poller registered: $key',
      name: 'PollingManager',
      level: 500,
    );
  }

  /// Unregister a poller
  void unregisterPoller({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';

    if (_activePollerKey == key) {
      _pauseActive();
    }

    _pollers.remove(key);

    developer.log(
      'Poller unregistered: $key',
      name: 'PollingManager',
      level: 500,
    );
  }

  /// Activate a poller (user navigated to this screen)
  void activatePoller({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';

    if (_activePollerKey == key) {
      developer.log(
        'Poller already active: $key',
        name: 'PollingManager',
        level: 500,
      );
      return;
    }

    // Pause current active poller
    if (_activePollerKey != null) {
      _pauseActive();
    }

    // Resume the new poller
    final poller = _pollers[key];
    if (poller != null) {
      _activePollerKey = key;
      poller.onResume();

      developer.log(
        'Poller activated: $key',
        name: 'PollingManager',
        level: 800, // High importance
      );

      _notifyListeners();
    }
  }

  /// Pause the currently active poller (user navigated away)
  void pauseActive() {
    _pauseActive();
  }

  /// Internal: Pause active poller
  void _pauseActive() {
    if (_activePollerKey != null) {
      final poller = _pollers[_activePollerKey];
      if (poller != null) {
        poller.onPause();

        developer.log(
          'Poller paused: $_activePollerKey',
          name: 'PollingManager',
          level: 800,
        );
      }

      _activePollerKey = null;
      _notifyListeners();
    }
  }

  /// Get the currently active poller key
  String? get activePollerKey => _activePollerKey;

  /// Check if a specific poller is active
  bool isPollerActive({
    required String featureName,
    required String resourceId,
  }) {
    final key = '$featureName:$resourceId';
    return _activePollerKey == key;
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
      'Active: $_activePollerKey\n'
      'Registered: ${_pollers.keys.join(", ")}\n'
      'Count: ${_pollers.length}',
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
