import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/core/polling/polling_manager.dart';

/// Registers a poller and records resume/pause transitions.
class _Probe {
  _Probe(this.feature, this.resource);

  final String feature;
  final String resource;
  var resumed = 0;
  var paused = 0;

  void register() {
    PollingManager.instance.registerPoller(
      featureName: feature,
      resourceId: resource,
      onResume: () => resumed++,
      onPause: () => paused++,
    );
  }

  void unregister() {
    PollingManager.instance.unregisterPoller(
      featureName: feature,
      resourceId: resource,
    );
  }

  bool get isActive => PollingManager.instance.isPollerActive(
    featureName: feature,
    resourceId: resource,
  );
}

/// No real feature uses this name, so making it active parks the manager in a
/// state where nothing auto-starts on registration.
const _idleFeature = '__idle__';

void main() {
  // PollingManager is a singleton and keeps its active feature between tests.
  // Park it on an unused feature so each test starts from a known state and
  // registrations do not auto-start before the test sets things up.
  setUp(() => PollingManager.instance.setActiveFeature(_idleFeature));

  tearDown(() {
    final manager = PollingManager.instance;
    manager.setActiveFeature(_idleFeature);
    manager.setVisibleResources('category_products', null);
    manager.setVisibleResources('cart', null);
    for (final key in manager.registeredPollers.toList()) {
      final parts = key.split(':');
      manager.unregisterPoller(
        featureName: parts.first,
        resourceId: parts.sublist(1).join(':'),
      );
    }
  });

  group('PollingManager visibility filter', () {
    test('with no filter, every poller for the active feature runs', () {
      final a = _Probe('category_products', 'a')..register();
      final b = _Probe('category_products', 'b')..register();

      PollingManager.instance.setActiveFeature('category_products');

      expect(a.isActive, isTrue);
      expect(b.isActive, isTrue);
    });

    test('only visible resources poll', () {
      final a = _Probe('category_products', 'a')..register();
      final b = _Probe('category_products', 'b')..register();
      final c = _Probe('category_products', 'c')..register();

      PollingManager.instance.setActiveFeature('category_products');
      PollingManager.instance.setVisibleResources('category_products', {'a', 'c'});

      expect(a.isActive, isTrue);
      expect(b.isActive, isFalse, reason: 'off-screen category must not poll');
      expect(c.isActive, isTrue);
    });

    test('scrolling swaps which pollers run', () {
      final a = _Probe('category_products', 'a')..register();
      final b = _Probe('category_products', 'b')..register();

      // Publish the visible set before the tab becomes active, mirroring the
      // real order: the grid measures its sections, then polling turns on.
      PollingManager.instance.setVisibleResources('category_products', {'a'});
      PollingManager.instance.setActiveFeature('category_products');
      expect(a.isActive, isTrue);
      expect(b.isActive, isFalse);
      expect(a.resumed, 1);
      expect(b.resumed, 0, reason: 'b was never on screen');

      // User scrolls: b comes into view, a leaves.
      PollingManager.instance.setVisibleResources('category_products', {'b'});
      expect(a.isActive, isFalse);
      expect(b.isActive, isTrue);
      expect(a.paused, 1);
      expect(b.resumed, 1);
    });

    test('re-publishing the same set is a no-op', () {
      final a = _Probe('category_products', 'a')..register();

      PollingManager.instance.setActiveFeature('category_products');
      PollingManager.instance.setVisibleResources('category_products', {'a'});
      final resumedAfterFirst = a.resumed;

      // The scroll handler republishes constantly; this must not churn timers.
      PollingManager.instance.setVisibleResources('category_products', {'a'});
      PollingManager.instance.setVisibleResources('category_products', {'a'});

      expect(a.resumed, resumedAfterFirst);
      expect(a.paused, 0);
    });

    test('a poller registered while off-screen does not auto-start', () {
      PollingManager.instance.setActiveFeature('category_products');
      PollingManager.instance.setVisibleResources('category_products', {'a'});

      // Pollers register after their first fetch resolves, i.e. potentially
      // after the visible set has already been published.
      final b = _Probe('category_products', 'b')..register();
      expect(b.isActive, isFalse);

      final a = _Probe('category_products', 'a')..register();
      expect(a.isActive, isTrue);
    });

    test('clearing the filter restores every poller', () {
      final a = _Probe('category_products', 'a')..register();
      final b = _Probe('category_products', 'b')..register();

      PollingManager.instance.setActiveFeature('category_products');
      PollingManager.instance.setVisibleResources('category_products', {'a'});
      expect(b.isActive, isFalse);

      PollingManager.instance.setVisibleResources('category_products', null);
      expect(a.isActive, isTrue);
      expect(b.isActive, isTrue);
    });

    test('a filter on one feature does not affect another', () {
      final category = _Probe('category_products', 'a')..register();
      final cart = _Probe('cart', 'lines')..register();

      PollingManager.instance.setVisibleResources('category_products', {'zzz'});

      PollingManager.instance.setActiveFeature('cart');
      expect(cart.isActive, isTrue, reason: 'cart has no filter of its own');

      PollingManager.instance.setActiveFeature('category_products');
      expect(category.isActive, isFalse);
    });

    test('switching features pauses the old feature regardless of filter', () {
      final category = _Probe('category_products', 'a')..register();
      final cart = _Probe('cart', 'lines')..register();

      PollingManager.instance.setActiveFeature('category_products');
      PollingManager.instance.setVisibleResources('category_products', {'a'});
      expect(category.isActive, isTrue);

      PollingManager.instance.setActiveFeature('cart');
      expect(category.isActive, isFalse);
      expect(cart.isActive, isTrue);
    });
  });
}
