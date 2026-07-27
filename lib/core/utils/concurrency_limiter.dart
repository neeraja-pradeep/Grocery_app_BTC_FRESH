import 'dart:async';
import 'dart:collection';

/// Caps how many async operations may be in flight at once.
///
/// WHY THIS EXISTS
/// ---------------
/// The Categories screen builds one sliver section per category, and every
/// section watches its own `categoryProductControllerProvider(id)`. Opening the
/// tab therefore kicks off one HTTP request per category *simultaneously* —
/// 25 categories means 25 concurrent requests, 25 concurrent response bodies
/// held in memory, and 25 JSON parses racing on the UI isolate.
///
/// Queuing them through a limiter keeps throughput essentially the same (the
/// socket and the server are the bottleneck, not the queue) while flattening
/// the memory and main-thread spike.
///
/// Note: the limiter only delays *issuing* the request, so Dio's connect and
/// receive timeouts start when the request actually goes out — queued work is
/// not at risk of spurious timeouts.
class ConcurrencyLimiter {
  ConcurrencyLimiter(this.maxConcurrent)
    : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  final int maxConcurrent;

  int _active = 0;
  final Queue<Completer<void>> _waiting = Queue<Completer<void>>();

  /// Number of operations currently running.
  int get activeCount => _active;

  /// Number of operations waiting for a slot.
  int get pendingCount => _waiting.length;

  /// Runs [action] once a slot is free, releasing the slot when it settles.
  ///
  /// Errors from [action] propagate to the caller unchanged; the slot is
  /// released either way.
  Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_active < maxConcurrent) {
      _active++;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      // Hand the slot straight to the next waiter without decrementing, so the
      // in-flight count never dips below the cap while work is queued.
      _waiting.removeFirst().complete();
      return;
    }
    _active--;
  }
}
