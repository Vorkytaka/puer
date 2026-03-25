import 'dart:async';
import 'dart:collection';

import 'package:puer/puer.dart';

/// A transformer that ensures effects are handled sequentially.
///
/// This transformer wraps an existing [EffectHandler] and modifies how it processes
/// effects by queuing them and processing one at a time in the order they are received.
/// This guarantees that no two effects are handled simultaneously.
///
/// Similar to how RxDart's concatMap operator works with streams, this transformer
/// ensures sequential processing of effects, which is particularly useful when handling
/// effects that depend on shared resources or when maintaining strict processing order
/// is required.
///
/// ### Example:
/// ```dart
/// // Using the extension method (recommended)
/// final handler = myEffectHandler.sequential();
///
/// // Or using the constructor directly
/// final sequentialHandler = SequentialTransformer(
///   handler: myEffectHandler,
/// );
/// ```
final class SequentialTransformer<Effect, Message>
    implements EffectHandler<Effect, Message>, Disposable {
  /// The wrapped effect handler that processes individual effects.
  final EffectHandler<Effect, Message> _handler;

  /// The internal queue that holds effects to be processed.
  ///
  /// Each entry in the queue is a tuple containing the effect and its associated
  /// [MsgEmitter] function.
  final _queue = Queue<(Effect, MsgEmitter<Message>)>();

  /// Tracks whether the handler is currently processing an effect.
  bool _isProcessing = false;

  /// Creates a new [SequentialTransformer].
  ///
  /// - [handler]: The effect handler that will process the effects sequentially.
  SequentialTransformer({
    required EffectHandler<Effect, Message> handler,
  }) : _handler = handler;

  /// Queues an effect for processing and starts the processing loop if not already active.
  ///
  /// - [effect]: The effect to process.
  /// - [emit]: A function to emit messages as a result of processing the effect.
  @override
  Future<void> call(
    Effect effect,
    MsgEmitter<Message> emit,
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

/// Extension methods for [EffectHandler] to add sequential processing.
///
/// This extension provides a convenient way to wrap an effect handler
/// with sequential processing logic without manually creating a [SequentialTransformer].
///
/// Example:
/// ```dart
/// final handler = MyEffectHandler().sequential();
/// ```
extension SequentialTransformerExt<Effect, Message>
    on EffectHandler<Effect, Message> {
  /// Wraps this handler to process effects sequentially.
  ///
  /// Returns a new [SequentialTransformer] that ensures effects are processed
  /// one at a time in the order they are received.
  EffectHandler<Effect, Message> sequential() =>
      SequentialTransformer(handler: this);
}
