import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'polling_manager.dart';

/// Navigation observer that automatically manages polling
///
/// When user navigates to a route, activates its polling.
/// When user navigates away, pauses its polling.
///
/// Add to MaterialApp:
/// ```dart
/// navigatorObservers: [PollingNavigationObserver()],
/// ```
class PollingNavigationObserver extends NavigatorObserver {
  /// Map route names to feature names for polling activation
  /// Example: '/product-details' → 'product_detail'
  static final Map<String, String> _routeToFeature = {
    '/product-details': 'product_detail',
    '/category': 'category',
    '/search': 'search',
    '/cart': 'cart',
  };

  /// Extract resource ID from route settings if available
  /// Can be overridden in subclasses for custom logic
  static String? extractResourceId(Route<dynamic> route) {
    if (route.settings.arguments is String) {
      return route.settings.arguments as String;
    }
    if (route.settings.arguments is Map) {
      final args = route.settings.arguments as Map;
      return args['id'] ?? args['resourceId'];
    }
    return null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigationChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // When popping back to previous route, activate its polling
    if (previousRoute != null) {
      _handleNavigationChange(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _handleNavigationChange(newRoute, 'replace');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Pause polling when route is removed
    _pauseCurrentPolling();
  }

  /// Handle navigation changes
  void _handleNavigationChange(Route<dynamic> route, String action) {
    final routeName = route.settings.name ?? 'unknown';
    final featureName = _routeToFeature[routeName];

    if (featureName == null) {
      developer.log(
        'Route "$routeName" has no associated feature for polling',
        name: 'PollingNavigationObserver',
        level: 500,
      );
      return;
    }

    // Extract resource ID if available
    final resourceId = extractResourceId(route) ?? 'default';

    developer.log(
      'Navigation $action: $routeName → Activating polling for $featureName:$resourceId',
      name: 'PollingNavigationObserver',
      level: 800,
    );

    PollingManager.instance.activatePoller(
      featureName: featureName,
      resourceId: resourceId,
    );
  }

  /// Pause current polling (helper)
  void _pauseCurrentPolling() {
    developer.log(
      'Pausing active polling',
      name: 'PollingNavigationObserver',
      level: 700,
    );
    PollingManager.instance.pauseActive();
  }

  /// Register a route-to-feature mapping
  static void registerRoute(String routeName, String featureName) {
    _routeToFeature[routeName] = featureName;
    developer.log(
      'Route mapping registered: $routeName → $featureName',
      name: 'PollingNavigationObserver',
    );
  }

  /// Get current route-to-feature mappings (for debugging)
  static Map<String, String> get routeMappings => Map.from(_routeToFeature);
}
