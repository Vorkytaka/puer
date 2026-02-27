import 'dart:async';

import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:test/test.dart';

void main() {
  group('AdaptEffectHandler', () {
    test('maps effect before delegating to inner handler', () {
      String? receivedInnerEffect;
      final inner = _CapturingHandler(onCall: (effect, emit) {
        receivedInnerEffect = effect;
      });

      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => 'mapped:$outer',
        messageMapper: (String inner) => inner,
      );

      handler('original', (_) {});

      expect(receivedInnerEffect, 'mapped:original');
    });

    test('maps message before forwarding to outer emit', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('inner_msg');
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => 'wrapped:$inner',
      );

      handler('effect', emitted.add);

      expect(emitted, ['wrapped:inner_msg']);
    });

    test('forwards multiple emits from inner handler', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('a');
        emit('b');
        emit('c');
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => inner.toUpperCase(),
      );

      handler('effect', emitted.add);

      expect(emitted, ['A', 'B', 'C']);
    });

    test('returns null synchronously when inner handler is synchronous', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('msg');
      });

      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => inner,
      );

      final result = handler('effect', (_) {});

      expect(result, isNull);
    });

    test('returns Future when inner handler is asynchronous', () async {
      final inner = _AsyncCapturingHandler(onCall: (effect, emit) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        emit('async_msg');
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => 'async:$inner',
      );

      final result = handler('effect', emitted.add);

      expect(result, isA<Future<void>>());
      await result;
      expect(emitted, ['async:async_msg']);
    });

    test('does not call outer emit when inner handler emits nothing', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        // intentionally no emit
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => inner,
      );

      handler('effect', emitted.add);

      expect(emitted, isEmpty);
    });

    test('applies both mappers independently on each call', () {
      final receivedEffects = <String>[];
      final inner = _CapturingHandler(onCall: (effect, emit) {
        receivedEffects.add(effect);
        emit('reply');
      });

      final emitted = <String>[];
      var callCount = 0;
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => 'e${++callCount}:$outer',
        messageMapper: (String inner) => 'm$callCount:$inner',
      );

      handler('first', emitted.add);
      handler('second', emitted.add);

      expect(receivedEffects, ['e1:first', 'e2:second']);
      expect(emitted, ['m1:reply', 'm2:reply']);
    });

    test('works with different inner and outer types', () {
      final inner = _IntHandler(onCall: (effect, emit) {
        emit(effect * 2);
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler<int, int, String, String>(
        effectHandler: inner,
        effectMapper: (String outer) => int.parse(outer),
        messageMapper: (int inner) => 'result:$inner',
      );

      handler('21', emitted.add);

      expect(emitted, ['result:42']);
    });

    test('identity adapt passes effect and message through unchanged', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('reply_to_$effect');
      });

      final emitted = <String>[];
      final handler = AdaptEffectHandler(
        effectHandler: inner,
        effectMapper: (String outer) => outer,
        messageMapper: (String inner) => inner,
      );

      handler('ping', emitted.add);

      expect(emitted, ['reply_to_ping']);
    });
  });

  group('AdaptEffectHandlerExt', () {
    test('.adapt() creates an AdaptEffectHandler with correct mappers', () {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('inner_response');
      });

      final emitted = <String>[];
      final handler = inner.adapt(
        effectMapper: (String outer) => 'adapted:$outer',
        messageMapper: (String inner) => 'wrapped:$inner',
      );

      String? capturedInnerEffect;
      final capturingInner = _CapturingHandler(onCall: (effect, emit) {
        capturedInnerEffect = effect;
        emit('inner_response');
      });

      final handler2 = capturingInner.adapt(
        effectMapper: (String outer) => 'adapted:$outer',
        messageMapper: (String inner) => 'wrapped:$inner',
      );

      handler2('original', emitted.add);

      expect(capturedInnerEffect, 'adapted:original');
      expect(emitted, ['wrapped:inner_response']);
      expect(handler, isA<EffectHandler<String, String>>());
    });

    test('.adapt() returns an EffectHandler of the outer types', () {
      final inner = _IntHandler(onCall: (effect, emit) {
        emit(effect + 1);
      });

      final adapted = inner.adapt<String, String>(
        effectMapper: (String outer) => int.parse(outer),
        messageMapper: (int inner) => '$inner',
      );

      expect(adapted, isA<EffectHandler<String, String>>());

      final emitted = <String>[];
      adapted('10', emitted.add);

      expect(emitted, ['11']);
    });

    test('.adapt() can be chained with other extensions', () async {
      final inner = _CapturingHandler(onCall: (effect, emit) {
        emit('response');
      });

      // Chain: adapt -> sequential
      final handler = inner
          .adapt(
            effectMapper: (String outer) => outer,
            messageMapper: (String inner) => inner,
          )
          .sequential();

      final emitted = <String>[];
      await handler('effect', emitted.add);

      expect(emitted, ['response']);
    });
  });
}

final class _CapturingHandler implements EffectHandler<String, String> {
  final void Function(String effect, MsgEmitter<String> emit) onCall;

  _CapturingHandler({required this.onCall});

  @override
  FutureOr<void> call(String effect, MsgEmitter<String> emit) {
    onCall(effect, emit);
  }
}

final class _AsyncCapturingHandler implements EffectHandler<String, String> {
  final Future<void> Function(String effect, MsgEmitter<String> emit) onCall;

  _AsyncCapturingHandler({required this.onCall});

  @override
  Future<void> call(String effect, MsgEmitter<String> emit) {
    return onCall(effect, emit);
  }
}

final class _IntHandler implements EffectHandler<int, int> {
  final void Function(int effect, MsgEmitter<int> emit) onCall;

  _IntHandler({required this.onCall});

  @override
  FutureOr<void> call(int effect, MsgEmitter<int> emit) {
    onCall(effect, emit);
  }
}
