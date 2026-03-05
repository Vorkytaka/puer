import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:puer/puer.dart';

/// Extension methods for [EffectHandler] to add isolate support.
///
/// Provides convenient methods to wrap an existing [EffectHandler] with
/// isolate-based execution capabilities.
extension IsolateEffectHandlerExt<Effect, Message>
    on EffectHandler<Effect, Message> {
  /// Wraps this [EffectHandler] to run in a separate isolate.
  ///
  /// Returns a new [IsolateEffectHandler] that will execute this handler's
  /// logic in a separate isolate, allowing computationally expensive or
  /// blocking tasks to run without affecting the main thread.
  ///
  /// Example:
  /// ```dart
  /// final handler = MyEffectHandler().isolated();
  /// ```
  ///
  /// See also:
  /// - [IsolateEffectHandler] for more details on isolate-based execution.
  EffectHandler<Effect, Message> isolated() =>
      IsolateEffectHandler(effectHandler: this);
}

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
/// - **Composition over inheritance**: Wraps any existing [EffectHandler] instance.
///
/// Example:
/// ```dart
/// // Using the extension method (recommended)
/// final handler = myEffectHandler.isolate();
///
/// // Or using the constructor directly
/// final handler = IsolateEffectHandler(
///   effectHandler: myEffectHandler,
/// );
/// ```
///
/// ### Note:
/// - Each effect is processed in its own isolate, which is spawned and terminated automatically.
/// - Because of how isolates work, be careful: not all objects can be sent. See [SendPort] docs.
@experimental
final class IsolateEffectHandler<Effect, Message>
    implements EffectHandler<Effect, Message> {
  /// The underlying effect handler that will be executed in an isolate.
  final EffectHandler<Effect, Message> _effectHandler;

  /// Creates an [IsolateEffectHandler] that wraps the given [effectHandler].
  ///
  /// The [effectHandler] will be executed in a separate isolate when effects
  /// are processed, allowing heavy computations to run without blocking the
  /// main thread.
  ///
  /// Example:
  /// ```dart
  /// final handler = IsolateEffectHandler(
  ///   effectHandler: myEffectHandler,
  /// );
  /// ```
  ///
  /// Or using the extension method:
  /// ```dart
  /// final handler = myEffectHandler.isolate();
  /// ```
  IsolateEffectHandler({
    required EffectHandler<Effect, Message> effectHandler,
  }) : _effectHandler = effectHandler;

  /// Processes the given effect in a separate isolate.
  ///
  /// - [effect]: The effect to be processed.
  /// - [emit]: A function to emit messages back to the main isolate.
  ///
  /// This method:
  /// 1. Creates a [ReceivePort] to receive messages from the isolate.
  /// 2. Spawns a new isolate and passes the effect, the handler's `call` function, and a [SendPort].
  /// 3. Listens for messages or the completion signal from the isolate.
  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _runInIsolate<Effect, Message>,
      _IsolateParams(effect, receivePort.sendPort, _effectHandler.call),
    );

    await for (final message in receivePort) {
      if (message is Message) {
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
  /// - Executes the provided handler function (`call`).
  /// - Emits messages or a completion signal back to the main isolate.
  static Future<void> _runInIsolate<Effect, Message>(
    _IsolateParams<Effect, Message> params,
  ) async {
    // Imitate emit, so, given handler will work as is
    void isolateEmit(Message message) {
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
class _IsolateParams<Effect, Message> {
  final Effect effect;
  final SendPort sendPort;
  final FunEffectHandler<Effect, Message> handler;

  const _IsolateParams(
    this.effect,
    this.sendPort,
    this.handler,
  );
}
