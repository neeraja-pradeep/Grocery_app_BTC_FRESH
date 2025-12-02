import 'dart:developer' as developer;
import 'polling_manager.dart';

/// Manages polling activation/deactivation for IndexedStack-based tab navigation
///
/// Unlike route-based navigation (which uses PollingNavigationObserver),
/// IndexedStack doesn't trigger navigator events. This controller manually
/// manages polling state based on tab index changes.
///
/// Usage in BottomNavigation:
/// ```dart
/// class _BottomNavigationState extends State<BottomNavigation> {
///   late final PollingTabController _pollingController;
///
///   @override
///   void initState() {
///     super.initState();
///     _pollingController = PollingTabController(
///       tabToFeature: {
///         0: 'category',
///         1: 'home',
///         2: 'wishlist',
///         3: 'cart',
///       },
///     );
///   }
///
///   @override
///   void dispose() {
///     _pollingController.dispose();
///     super.dispose();
///   }
///
///   void _onTabSelected(int index) {
///     setState(() => _currentIndex = index);
///     _pollingController.selectTab(index);  // ← Activate/pause polling
///   }
/// }
/// ```
class PollingTabController {
  PollingTabController({
    required Map<int, String> tabToFeature,
    this.defaultResourceId = 'default',
  }) : _tabToFeature = tabToFeature {
    developer.log(
      'PollingTabController created for ${_tabToFeature.length} tabs',
      name: 'PollingTabController',
      level: 500,
    );
  }

  /// Map of tab index to feature name
  /// Example: {0: 'category', 1: 'home', 2: 'wishlist', 3: 'cart'}
  final Map<int, String> _tabToFeature;

  /// Default resource ID for tabs without specific resources
  final String defaultResourceId;

  /// Currently active tab index
  int? _currentTabIndex;

  /// Get currently active tab
  int? get currentTabIndex => _currentTabIndex;

  /// Get feature name for a tab
  String? getFeatureForTab(int tabIndex) => _tabToFeature[tabIndex];

  /// Select a tab and manage polling activation/deactivation
  ///
  /// This sets the active feature, which:
  /// 1. Pauses ALL pollers from the previous feature (e.g., all category_products pollers)
  /// 2. Allows pollers from the new feature to run
  ///
  /// This ensures that when you switch from Category tab to Cart tab:
  /// - All category product API checks STOP
  /// - Cart API checks START
  void selectTab(int tabIndex) {
    if (_currentTabIndex == tabIndex) {
      // Already on this tab
      return;
    }

    final featureName = _tabToFeature[tabIndex];
    if (featureName == null) {
      developer.log(
        'No polling configuration for tab $tabIndex',
        name: 'PollingTabController',
        level: 500,
      );
      return;
    }

    final previousFeature = _currentTabIndex != null
        ? _tabToFeature[_currentTabIndex]
        : null;
    _currentTabIndex = tabIndex;

    developer.log(
      'Tab changed: $previousFeature → $featureName (tab $tabIndex)',
      name: 'PollingTabController',
      level: 800,
    );

    // Set the active feature - this pauses ALL pollers from other features
    // and allows pollers from this feature to run
    PollingManager.instance.setActiveFeature(featureName);
  }

  /// Manual pause (for when using IndexedStack outside of tab context)
  void pauseCurrentTab() {
    if (_currentTabIndex != null) {
      developer.log(
        'Pausing polling for tab $_currentTabIndex',
        name: 'PollingTabController',
        level: 700,
      );
      PollingManager.instance.pauseActive();
    }
  }

  /// Cleanup
  void dispose() {
    developer.log(
      'PollingTabController disposed',
      name: 'PollingTabController',
      level: 500,
    );
  }

  /// Get tab-to-feature mappings (for debugging)
  Map<int, String> get tabMappings => Map.from(_tabToFeature);

  /// Print current state
  void debugPrintState() {
    developer.log(
      'PollingTabController State:\n'
      'Current Tab: $_currentTabIndex\n'
      'Tab Mappings: $_tabToFeature\n'
      'Active Feature: ${_currentTabIndex != null ? _tabToFeature[_currentTabIndex] : "none"}',
      name: 'PollingTabController',
    );
  }
}
