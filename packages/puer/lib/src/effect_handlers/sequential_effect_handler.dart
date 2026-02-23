import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import '../../feature.dart';

/// An [EffectHandler] implementation that ensures effects are handled sequentially.
///
/// This handler processes effects one at a time in the order they are received,
/// queuing subsequent effects until the current one has completed. This guarantees
/// that no two effects are handled simultaneously, which is particularly useful
/// when handling effects that depend on shared resources or when maintaining strict
/// processing order is required.
///
/// ### Example:
/// ```dart
/// final sequentialHandler = SequentialEffectHandler(
///   handler: myEffectHandler,
/// );
/// ```
@experimental
final class SequentialEffectHandler<Effect, Msg>
    implements EffectHandler<Effect, Msg>, Disposable {
  /// The wrapped effect handler that processes individual effects.
  final EffectHandler<Effect, Msg> _handler;

  /// The internal queue that holds effects to be processed.
  ///
  /// Each entry in the queue is a tuple containing the effect and its associated
  /// [MsgEmitter] function.
  final _queue = Queue<(Effect, MsgEmitter<Msg>)>();

  /// Tracks whether the handler is currently processing an effect.
  bool _isProcessing = false;

  /// Creates a new [SequentialEffectHandler].
  ///
  /// - [handler]: The effect handler that will process the effects sequentially.
  SequentialEffectHandler({
    required EffectHandler<Effect, Msg> handler,
  }) : _handler = handler;

  /// Queues an effect for processing and starts the processing loop if not already active.
  ///
  /// - [effect]: The effect to process.
  /// - [emit]: A function to emit messages as a result of processing the effect.
  @override
  Future<void> call(
    Effect effect,
    MsgEmitter<Msg> emit,
  ) async {
    _queue.add((effect, emit));
    if (!_isProcessing) {
      unawaited(_process());
    }
  }

  /// Processes the queued effects sequentially.
  ///
  /// This method iterates through the queue, invoking the wrapped handler for each effect.
  /// Processing continues until the queue is empty, at which point `_isProcessing` is set to `false`.
  Future<void> _process() async {
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final (effect, emit) = _queue.removeFirst();
      await _handler.call(effect, emit);
    }
    _isProcessing = false;
  }

  /// Disposes the handler, clearing the queue.
  ///
  /// This method ensures that no pending effects remain in the queue when the handler
  /// is no longer needed.
  @override
  Future<void> dispose() async {
    _queue.clear();
  }
}
