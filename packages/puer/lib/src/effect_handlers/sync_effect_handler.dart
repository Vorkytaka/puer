import 'package:meta/meta.dart';

import '../feature/core/feature.dart';

/// A synchronous [EffectHandler] implementation for processing effects.
///
/// This abstract class provides a structured way to define synchronous effect
/// handling logic. Subclasses must implement the [handle] method, which processes
/// the effect and emits messages without using asynchronous operations.
///
/// ### Usage:
/// To create a custom synchronous effect handler, subclass [SyncEffectHandler] and
/// implement the [handle] method. The `handle` method will be invoked whenever
/// an effect of the specified type is triggered.
///
/// Example:
/// ```dart
/// final class MySyncEffectHandler extends SyncEffectHandler<MyEffect, MyMsg> {
///   @override
///   Null handle(MyEffect effect, MsgEmitter<MyMsg> emit) {
///     if (effect.shouldEmit) {
///       emit(MyMsg.success(effect.data));
///     }
///   }
/// }
/// ```
@experimental
abstract base class SyncEffectHandler<Effect, Msg>
    implements EffectHandler<Effect, Msg> {
  /// Creates a [SyncEffectHandler].
  const SyncEffectHandler();

  /// Defines the synchronous logic for processing the effect.
  ///
  /// - [effect]: The effect to be handled.
  /// - [emit]: A function to emit messages as a result of handling the effect.
  ///
  /// Subclasses must override this method to implement their specific
  /// synchronous effect handling logic.
  ///
  /// **Note:** The return type is explicitly set to [Null] to ensure
  /// that this method is not mistakenly implemented with asynchronous behavior.
  Null handle(Effect effect, MsgEmitter<Msg> emit);

  /// Invokes the [handle] method to process the effect synchronously.
  ///
  /// This method ensures that the effect is handled immediately and without
  /// any asynchronous operations.
  ///
  /// - [effect]: The effect to be handled.
  /// - [emit]: A function to emit messages as a result of handling the effect.
  @override
  void call(Effect effect, MsgEmitter<Msg> emit) {
    handle(effect, emit);
  }
}
