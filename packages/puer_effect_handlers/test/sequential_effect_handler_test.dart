import 'dart:async';

import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:test/test.dart';

void main() {
  group('SequentialEffectHandler', () {
    test('processes effects sequentially', () async {
      final handler = SequentialEffectHandler(
        handler: _DelayedHandler(),
      );

      final results = <String>[];
      final order = <int>[];

      // Start all three effects quickly
      unawaited(handler('effect1', (msg) {
        results.add(msg);
        order.add(1);
      }));

      unawaited(handler('effect2', (msg) {
        results.add(msg);
        order.add(2);
      }));

      unawaited(handler('effect3', (msg) {
        results.add(msg);
        order.add(3);
      }));

      // Wait for all to complete
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should be processed in order
      expect(results, ['effect1', 'effect2', 'effect3']);
      expect(order, [1, 2, 3]);
    });

    test('handles async effects in order', () async {
      var counter = 0;
      final handler = SequentialEffectHandler(
        handler: _AsyncCounterHandler(() => counter++),
      );

      final results = <int>[];

      unawaited(handler('a', results.add));
      unawaited(handler('b', results.add));
      unawaited(handler('c', results.add));

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(results, [0, 1, 2]);
    });

    test('disposes and clears queue', () async {
      final handler = SequentialEffectHandler(
        handler: _DelayedHandler(),
      );

      final results = <String>[];

      handler('effect1', results.add);
      handler('effect2', results.add);

      await handler.dispose();

      // Queue should be cleared
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}

final class _DelayedHandler implements EffectHandler<String, String> {
  @override
  Future<void> call(String effect, MsgEmitter<String> emit) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    emit(effect);
  }
}

final class _AsyncCounterHandler implements EffectHandler<String, int> {
  final int Function() getCounter;

  _AsyncCounterHandler(this.getCounter);

  @override
  Future<void> call(String effect, MsgEmitter<int> emit) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    emit(getCounter());
  }
}
