import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/core/utils/concurrency_limiter.dart';

void main() {
  group('ConcurrencyLimiter', () {
    test('never exceeds the cap, and still runs everything', () async {
      final limiter = ConcurrencyLimiter(3);
      final completers = <Completer<void>>[];
      var running = 0;
      var peak = 0;
      var completed = 0;

      final futures = List.generate(12, (_) {
        return limiter.run(() async {
          running++;
          if (running > peak) peak = running;
          final completer = Completer<void>();
          completers.add(completer);
          await completer.future;
          running--;
          completed++;
        });
      });

      // Let the first batch start.
      await Future<void>.delayed(Duration.zero);
      expect(peak, 3, reason: 'only `maxConcurrent` may start immediately');

      // Drain: releasing one task lets exactly one queued task start.
      while (completed < 12) {
        final pending = completers.where((c) => !c.isCompleted).toList();
        for (final c in pending) {
          c.complete();
        }
        await Future<void>.delayed(Duration.zero);
      }

      await Future.wait(futures);
      expect(completed, 12);
      expect(peak, lessThanOrEqualTo(3));
      expect(limiter.activeCount, 0, reason: 'all slots released');
      expect(limiter.pendingCount, 0);
    });

    test('releases the slot when the action throws', () async {
      final limiter = ConcurrencyLimiter(1);

      await expectLater(
        limiter.run(() async => throw StateError('boom')),
        throwsStateError,
      );

      // The slot must be reusable, otherwise one failure deadlocks the queue.
      final result = await limiter.run(() async => 'ok');
      expect(result, 'ok');
      expect(limiter.activeCount, 0);
    });

    test('queued work runs in FIFO order', () async {
      final limiter = ConcurrencyLimiter(1);
      final order = <int>[];
      final gate = Completer<void>();

      final first = limiter.run(() async {
        await gate.future;
        order.add(0);
      });
      final rest = [
        for (var i = 1; i <= 3; i++)
          limiter.run(() async {
            order.add(i);
          }),
      ];

      gate.complete();
      await Future.wait([first, ...rest]);

      expect(order, [0, 1, 2, 3]);
    });
  });
}
