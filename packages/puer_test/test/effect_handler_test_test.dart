import 'dart:async';

import 'package:puer/feature.dart';
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

class _MockEffectHandler implements EffectHandler {
  @override
  // ignore:type_annotate_public_apis
  FutureOr<void> call(effect, MsgEmitter emit) {
    switch (effect) {
      case 1:
        emit('message');
        break;
      case 2:
        // no messages
        break;
      case 3:
        emit('message1');
        emit('message2');
        emit('message3');
        break;
    }
  }
}

void main() {
  group('EffectHandlerTests', () {
    test('should test the behavior of the EffectHandler', () async {
      final handler = _MockEffectHandler();

      await handler.test(
        effect: 1,
        expectedMessages: ['message'],
      );
    });

    test('should test the behavior of the EffectHandler with no messages',
        () async {
      final handler = _MockEffectHandler();

      await handler.test(
        effect: 0,
      );
    });

    test('should test the behavior of the EffectHandler with multiple messages',
        () async {
      final handler = _MockEffectHandler();

      await handler.test(
        effect: 3,
        expectedMessages: ['message1', 'message2', 'message3'],
      );
    });
  });
}
