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

    _currentTabIndex = tabIndex;

    developer.log(
      'Tab selected: $tabIndex → Activating polling for $featureName',
      name: 'PollingTabController',
      level: 800,
    );

    // Activate the new tab's polling
    PollingManager.instance.activatePoller(
      featureName: featureName,
      resourceId: defaultResourceId,
    );
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
