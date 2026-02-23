import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncEffectHandler', () {
    test('calls handle method asynchronously', () async {
      final handler = _TestAsyncHandler();
      final emitted = <String>[];

      await handler('test_effect', emitted.add);

      expect(emitted, ['success:test_effect']);
    });

    test('handles errors in async operations', () async {
      final handler = _TestAsyncHandlerWithError();
      final emitted = <String>[];

      await handler('error', emitted.add);

      expect(emitted, ['error:Exception: test error']);
    });
  });

  group('SyncEffectHandler', () {
    test('calls handle method synchronously', () {
      final handler = _TestSyncHandler();
      final emitted = <String>[];

      handler('test_effect', emitted.add);

      expect(emitted, ['sync:test_effect']);
    });
  });
}

final class _TestAsyncHandler extends AsyncEffectHandler<String, String> {
  @override
  Future<void> handle(String effect, MsgEmitter<String> emit) async {
    await Future<void>.delayed(Duration(milliseconds: 10));
    emit('success:$effect');
  }
}

final class _TestAsyncHandlerWithError
    extends AsyncEffectHandler<String, String> {
  @override
  Future<void> handle(String effect, MsgEmitter<String> emit) async {
    try {
      throw Exception('test error');
    } catch (e) {
      emit('error:$e');
    }
  }
}

final class _TestSyncHandler extends SyncEffectHandler<String, String> {
  @override
  Null handle(String effect, MsgEmitter<String> emit) {
    emit('sync:$effect');
  }
}
