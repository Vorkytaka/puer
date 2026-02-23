import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../feature/core/feature.dart';

/// An [EffectHandler] implementation that processes effects in a separate isolate.
///
/// This handler offloads effect processing to a separate isolate, allowing
/// computationally expensive or blocking tasks to run without affecting the main thread.
/// It is particularly useful for tasks like heavy computations, parsing, or file I/O
/// that benefit from parallelism provided by isolates.
///
/// ### Key Features:
/// - **Isolate-based execution**: Effects are processed in an independent isolate.
/// - **Message emission**: Allows the handler to emit messages back to the main isolate.
/// - **Encapsulation**: Abstracts away the complexity of managing isolates.
///
/// Example:
/// ```dart
/// final class MyEffectHandler extends IsolateEffectHandler<MyEffect, MyMsg> {
///   @override
///   Future<void> handle(MyEffect effect, MsgEmitter<MyMsg> emit) async {
///     // Perform expensive work here
///     final result = await performHeavyComputation(effect.data);
///     emit(MyMsg(result));
///   }
/// }
/// ```
///
/// ### Note:
/// - Each effect is processed in its own isolate, which is spawned and terminated automatically.
/// - Because of how isolate works you should be careful, not all object can be send. See [SendPort] docs.
@experimental
abstract base class IsolateEffectHandler<Effect, Msg>
    implements EffectHandler<Effect, Msg> {
  /// Creates an [IsolateEffectHandler].
  const IsolateEffectHandler();

  /// Defines the logic for processing the effect within the isolate.
  ///
  /// - [effect]: The effect to be processed.
  /// - [emit]: A function to emit messages back to the main isolate.
  ///
  /// Subclasses must override this method with their effect handling logic.
  FutureOr<void> handle(Effect effect, MsgEmitter<Msg> emit);

  /// Processes the given effect in a separate isolate.
  ///
  /// - [effect]: The effect to be processed.
  /// - [emit]: A function to emit messages back to the main isolate.
  ///
  /// This method:
  /// 1. Creates a [ReceivePort] to receive messages from the isolate.
  /// 2. Spawns a new isolate and passes the effect, [handle], and a [SendPort].
  /// 3. Listens for messages or the completion signal from the isolate.
  @override
  Future<void> call(Effect effect, MsgEmitter<Msg> emit) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _runInIsolate<Effect, Msg>,
      _IsolateParams(effect, receivePort.sendPort, handle),
    );

    await for (final message in receivePort) {
      if (message is Msg) {
        emit(message);
      } else if (message == _doneEvent) {
        receivePort.close();
        isolate.kill(priority: Isolate.immediate);
        break;
      }
    }
  }

  /// The function executed within the isolate.
  ///
  /// This function:
  /// - Executes the [handle] method provided by the handler.
  /// - Emits messages or a completion signal back to the main isolate.
  static Future<void> _runInIsolate<Effect, Msg>(
    _IsolateParams<Effect, Msg> params,
  ) async {
    // Imitate emit, so, given handler will work as is
    void isolateEmit(Msg message) {
      params.sendPort.send(message);
    }

    await params.handler(params.effect, isolateEmit);

    params.sendPort.send(_doneEvent);
  }

  /// A constant representing the completion event sent by the isolate.
  static const _doneEvent = 'done';
}

/// Parameters passed to the isolate for effect processing.
///
/// This includes:
/// - [effect]: The effect to be processed.
/// - [sendPort]: A [SendPort] for communication with the main isolate.
/// - [handler]: The handle method from the [IsolateEffectHandler].
class _IsolateParams<Effect, Msg> {
  final Effect effect;
  final SendPort sendPort;
  final FunEffectHandler<Effect, Msg> handler;

  const _IsolateParams(
    this.effect,
    this.sendPort,
    this.handler,
  );
}
