import 'dart:async';

import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:test/test.dart';

void main() {
  group('DebounceEffectHandler', () {
    test('debounces rapid calls', () async {
      final innerHandler = _CountingHandler();
      final handler = DebounceEffectHandler(
        duration: const Duration(milliseconds: 50),
        handler: innerHandler,
      );

      final emitted = <String>[];

      // Rapid calls
      handler('effect1', emitted.add);
      handler('effect2', emitted.add);
      handler('effect3', emitted.add);

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only last effect should be processed
      expect(innerHandler.callCount, 1);
      expect(emitted, ['effect3']);
    });

    test('allows calls after debounce period', () async {
      final innerHandler = _CountingHandler();
      final handler = DebounceEffectHandler(
        duration: const Duration(milliseconds: 50),
        handler: innerHandler,
      );

      final emitted = <String>[];

      handler('effect1', emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      handler('effect2', emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(innerHandler.callCount, 2);
      expect(emitted, ['effect1', 'effect2']);
    });

    test('disposes properly', () async {
      final handler = DebounceEffectHandler(
        duration: const Duration(milliseconds: 50),
        handler: _CountingHandler(),
      );

      final emitted = <String>[];
      handler('effect', emitted.add);

      await handler.dispose();

      // After dispose, pending effects should be canceled
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}

final class _CountingHandler implements EffectHandler<String, String> {
  int callCount = 0;

  @override
  FutureOr<void> call(String effect, MsgEmitter<String> emit) {
    callCount++;
    emit(effect);
  }
}
