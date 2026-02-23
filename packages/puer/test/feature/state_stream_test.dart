import 'dart:async';

import 'package:puer/src/feature/core/state_stream.dart';
import 'package:test/test.dart';

void main() {
  group('StateStream', () {
    late StateStream<int> subject;

    setUp(() {
      subject = StateStream.seeded(0);
    });

    tearDown(() async {
      await subject.close();
    });

    group('value', () {
      test('returns the seed value initially', () {
        expect(subject.value, 0);
      });

      test('returns the latest value after add', () {
        subject.add(1);
        subject.add(2);
        expect(subject.value, 2);
      });
    });

    group('stream', () {
      test('emits the seed value synchronously on listen', () {
        final values = <int>[];
        subject.stream.listen(values.add);

        // No await — the seed must be delivered synchronously.
        expect(values, [0]);
      });

      test('emits seed value and subsequent values in order', () async {
        final values = <int>[];
        subject.stream.listen(values.add);

        subject.add(1);
        subject.add(2);

        await Future.delayed(Duration.zero);
        expect(values, [0, 1, 2]);
      });

      test('emits the current value at the time of listen, not the seed', () {
        subject.add(10);
        subject.add(20);

        final values = <int>[];
        subject.stream.listen(values.add);

        expect(values, [20]);
      });

      test(
        'does not miss values added synchronously after listen',
        () async {
          final values = <int>[];
          subject.stream.listen(values.add);
          subject.add(1);

          await Future.delayed(Duration.zero);
          expect(values, [0, 1]);
        },
      );

      test('each stream getter call creates an independent subscription',
          () async {
        final values1 = <int>[];
        final values2 = <int>[];

        subject.stream.listen(values1.add);
        subject.add(1);
        subject.stream.listen(values2.add);
        subject.add(2);

        await Future.delayed(Duration.zero);
        // First listener: seed(0), then 1, then 2
        expect(values1, [0, 1, 2]);
        // Second listener: current value at subscribe time(1), then 2
        expect(values2, [1, 2]);
      });
    });

    group('close', () {
      test('closes the stream when StateStream is closed', () async {
        final completer = Completer<void>();
        subject.stream.listen(null, onDone: completer.complete);

        await subject.close();
        await completer.future;
      });

      test('value remains accessible after close', () async {
        subject.add(42);
        await subject.close();
        expect(subject.value, 42);
      });
    });

    group('subscription lifecycle', () {
      test('cancelling the subscription stops receiving values', () async {
        final values = <int>[];
        final subscription = subject.stream.listen(values.add);

        subject.add(1);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        subject.add(2);
        await Future.delayed(Duration.zero);

        expect(values, [0, 1]);
      });

      test(
        'inner subscription is cancelled when outer subscription is cancelled',
        () async {
          // This test verifies there is no memory leak:
          // when we cancel the listener on the stream returned by
          // StateStream.stream, the internal subscription to the
          // broadcast controller must also be cancelled.

          final subscription = subject.stream.listen(null);
          await subscription.cancel();

          // After cancel, adding values should not throw and should not
          // be forwarded. We verify indirectly: if the inner subscription
          // leaked, the broadcast controller would still have a listener,
          // which we can check via hasListener.
          expect(subject.hasListener, isFalse);
        },
      );

      test(
        'inner subscription is cleaned up when StateStream is closed',
        () async {
          final done = Completer<void>();
          subject.stream.listen(null, onDone: done.complete);

          expect(subject.hasListener, isTrue);
          await subject.close();
          await done.future;

          // After close and done delivery, no listeners should remain
          // on the broadcast controller.
          expect(subject.hasListener, isFalse);
        },
      );

      test(
        'multiple listeners are all cleaned up on cancel',
        () async {
          final sub1 = subject.stream.listen(null);
          final sub2 = subject.stream.listen(null);

          expect(subject.hasListener, isTrue);

          await sub1.cancel();
          await sub2.cancel();

          expect(subject.hasListener, isFalse);
        },
      );
    });

    group('pause and resume', () {
      test('buffers events while paused and delivers on resume', () async {
        final values = <int>[];
        final subscription = subject.stream.listen(values.add);

        // Seed is delivered synchronously.
        expect(values, [0]);

        subscription.pause();
        subject.add(1);
        subject.add(2);

        await Future.delayed(Duration.zero);
        // Values should be buffered, not yet delivered.
        expect(values, [0]);

        subscription.resume();
        await Future.delayed(Duration.zero);
        expect(values, [0, 1, 2]);
        await subscription.cancel();
      });
    });
  });
}
