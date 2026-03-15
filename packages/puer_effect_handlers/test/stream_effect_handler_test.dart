import 'dart:async';

import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:test/test.dart';

// Test fixtures
sealed class TestEffect {}

final class StartStream extends TestEffect {}

final class StopStream extends TestEffect {}

final class OtherEffect extends TestEffect {}

sealed class TestMessage {}

final class ValueMessage extends TestMessage {
  final int value;

  ValueMessage(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueMessage &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class ErrorMessage extends TestMessage {
  final String error;

  ErrorMessage(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorMessage &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

final class CompletedMessage extends TestMessage {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedMessage && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

void main() {
  group('StreamEffectHandler', () {
    late StreamController<int> streamController;
    late List<TestMessage> emittedMessages;

    void emitFunction(TestMessage message) {
      emittedMessages.add(message);
    }

    setUp(() {
      streamController = StreamController<int>.broadcast();
      emittedMessages = [];
    });

    tearDown(() async {
      await streamController.close();
    });

    test('starts subscription on start effect and emits mapped values',
        () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      expect(handler.isActive, isFalse);

      // Start subscription
      await handler.call(StartStream(), emitFunction);

      expect(handler.isActive, isTrue);

      // Emit values
      streamController.add(1);
      streamController.add(2);
      streamController.add(3);

      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [
        ValueMessage(1),
        ValueMessage(2),
        ValueMessage(3),
      ]);

      await handler.dispose();
    });

    test('stops subscription on end effect', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      // Start subscription
      await handler.call(StartStream(), emitFunction);
      expect(handler.isActive, isTrue);

      streamController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Stop subscription
      await handler.call(StopStream(), emitFunction);
      expect(handler.isActive, isFalse);

      // Values after stop should not be emitted
      streamController.add(2);
      streamController.add(3);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [ValueMessage(1)]);
    });

    test('supports restart after stopping', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      // First cycle: start -> emit -> stop
      await handler.call(StartStream(), emitFunction);
      streamController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));
      await handler.call(StopStream(), emitFunction);

      expect(emittedMessages, [ValueMessage(1)]);
      expect(handler.isActive, isFalse);

      // Second cycle: start -> emit
      await handler.call(StartStream(), emitFunction);
      expect(handler.isActive, isTrue);

      streamController.add(2);
      streamController.add(3);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [
        ValueMessage(1),
        ValueMessage(2),
        ValueMessage(3),
      ]);

      await handler.dispose();
    });

    test('handles multiple start effects by restarting', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      // First start
      await handler.call(StartStream(), emitFunction);
      streamController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Second start (should restart)
      await handler.call(StartStream(), emitFunction);
      expect(handler.isActive, isTrue);

      streamController.add(2);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [ValueMessage(1), ValueMessage(2)]);

      await handler.dispose();
    });

    test('handles error with onError callback', () async {
      final errorController = StreamController<int>();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: errorController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onError: (error, stackTrace) => ErrorMessage(error.toString()),
      );

      await handler.call(StartStream(), emitFunction);

      errorController.add(1);
      errorController.addError(Exception('Test error'));
      errorController.add(2);

      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [
        ValueMessage(1),
        ErrorMessage('Exception: Test error'),
        ValueMessage(2),
      ]);

      await handler.dispose();
      await errorController.close();
    });

    test('ignores errors when onError returns null', () async {
      final errorController = StreamController<int>();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: errorController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onError: (error, stackTrace) => null, // Ignore all errors
      );

      await handler.call(StartStream(), emitFunction);

      errorController.add(1);
      errorController.addError(Exception('Test error'));
      errorController.add(2);

      await Future<void>.delayed(Duration(milliseconds: 10));

      // Error should be ignored
      expect(emittedMessages, [ValueMessage(1), ValueMessage(2)]);

      await handler.dispose();
      await errorController.close();
    });

    test('silently ignores errors when onError is not provided', () async {
      final errorController = StreamController<int>();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: errorController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      await handler.call(StartStream(), emitFunction);

      errorController.add(1);
      errorController.addError(Exception('Test error'));
      errorController.add(2);

      await Future<void>.delayed(Duration(milliseconds: 10));

      // Error should be silently ignored, subscription stays active
      expect(emittedMessages, [ValueMessage(1), ValueMessage(2)]);
      expect(handler.isActive, isTrue);

      await handler.dispose();
      await errorController.close();
    });

    test('handles stream completion with onDone callback', () async {
      final completeController = StreamController<int>();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: completeController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onDone: () => CompletedMessage(),
      );

      await handler.call(StartStream(), emitFunction);
      expect(handler.isActive, isTrue);

      completeController.add(1);
      completeController.add(2);
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Close the stream
      await completeController.close();
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [
        ValueMessage(1),
        ValueMessage(2),
        CompletedMessage(),
      ]);

      // Handler should be inactive after stream completes
      expect(handler.isActive, isFalse);

      await handler.dispose();
    });

    test('does not emit message when onDone returns null', () async {
      final completeController = StreamController<int>();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: completeController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onDone: () => null, // No completion message
      );

      await handler.call(StartStream(), emitFunction);

      completeController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));

      await completeController.close();
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Only value message, no completion message
      expect(emittedMessages, [ValueMessage(1)]);
      expect(handler.isActive, isFalse);

      await handler.dispose();
    });

    test('end effect before start effect does nothing', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      expect(handler.isActive, isFalse);

      // Try to stop before starting
      await handler.call(StopStream(), emitFunction);

      expect(handler.isActive, isFalse);
      expect(emittedMessages, isEmpty);

      await handler.dispose();
    });

    test('ignores effects that do not match predicates', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      // Send other effect (not start or stop)
      await handler.call(OtherEffect(), emitFunction);

      expect(handler.isActive, isFalse);
      expect(emittedMessages, isEmpty);

      await handler.dispose();
    });

    test('dispose cleans up subscription properly', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      await handler.call(StartStream(), emitFunction);
      expect(handler.isActive, isTrue);

      streamController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));

      await handler.dispose();
      expect(handler.isActive, isFalse);

      // Values after dispose should not be emitted
      streamController.add(2);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [ValueMessage(1)]);
    });

    test('dispose when not active does not throw', () async {
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: streamController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      expect(handler.isActive, isFalse);

      // Should not throw
      await handler.dispose();

      expect(handler.isActive, isFalse);
    });

    test('extension method toEffectHandler creates handler', () async {
      final handler =
          streamController.stream.toEffectHandler<TestEffect, TestMessage>(
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onError: (error, stackTrace) => ErrorMessage(error.toString()),
        onDone: () => CompletedMessage(),
      );

      expect(handler, isA<StreamEffectHandler<int, TestEffect, TestMessage>>());

      await handler.call(StartStream(), emitFunction);

      streamController.add(42);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [ValueMessage(42)]);

      // Cast to access dispose method
      await (handler as StreamEffectHandler<int, TestEffect, TestMessage>)
          .dispose();
    });

    test('can restart after stream completes naturally', () async {
      final completeController = StreamController<int>.broadcast();
      final handler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: completeController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
        onDone: () => CompletedMessage(),
      );

      // First cycle: start -> emit -> stream completes
      await handler.call(StartStream(), emitFunction);
      completeController.add(1);
      await Future<void>.delayed(Duration(milliseconds: 10));
      await completeController.close();
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(handler.isActive, isFalse);
      expect(emittedMessages, [ValueMessage(1), CompletedMessage()]);

      // Create new controller for restart (can't reuse closed controller)
      final newController = StreamController<int>.broadcast();
      final newHandler = StreamEffectHandler<int, TestEffect, TestMessage>(
        stream: newController.stream,
        mapper: (value) => ValueMessage(value),
        isStartEffect: (effect) => effect is StartStream,
        isEndEffect: (effect) => effect is StopStream,
      );

      emittedMessages.clear();

      await newHandler.call(StartStream(), emitFunction);
      expect(newHandler.isActive, isTrue);

      newController.add(2);
      await Future<void>.delayed(Duration(milliseconds: 10));

      expect(emittedMessages, [ValueMessage(2)]);

      await newHandler.dispose();
      await newController.close();
    });
  });
}
