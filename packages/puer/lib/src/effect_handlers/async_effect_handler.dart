import 'package:meta/meta.dart';

import '../feature/core/feature.dart';

/// An [EffectHandler] implementation for handling effects asynchronously.
///
/// This abstract class provides a structured way to define asynchronous effect
/// handling logic. Subclasses are required to implement the [handle] method,
/// which processes the effect and emits messages if needed.
///
/// ### Usage:
/// To create a custom asynchronous effect handler, subclass [AsyncEffectHandler] and
/// implement the [handle] method. The `handle` method will be called whenever an
/// effect of the specified type is triggered.
///
/// Example:
/// ```dart
/// final class MyAsyncEffectHandler extends AsyncEffectHandler<MyEffect, MyMsg> {
///   @override
///   Future<void> handle(MyEffect effect, MsgEmitter<MyMsg> emit) async {
///     try {
///       final result = await performAsyncOperation(effect.data);
///       emit(MyMsg.success(result));
///     } catch (error) {
///       emit(MyMsg.failure(error));
///     }
///   }
/// }
/// ```
@experimental
abstract base class AsyncEffectHandler<Effect, Msg>
    implements EffectHandler<Effect, Msg> {
  /// Creates an [AsyncEffectHandler].
  const AsyncEffectHandler();

  /// Defines the asynchronous logic for processing the effect.
  ///
  /// - [effect]: The effect to be handled.
  /// - [emit]: A function to emit messages as a result of handling the effect.
  ///
  /// Subclasses must override this method to implement their specific
  /// asynchronous effect handling logic.
  Future<void> handle(Effect effect, MsgEmitter<Msg> emit);

  /// Handles the effect by invoking the [handle] method.
  ///
  /// This method ensures that the provided effect is processed asynchronously,
  /// as defined in the [handle] method.
  ///
  /// - [effect]: The effect to be handled.
  /// - [emit]: A function to emit messages as a result of handling the effect.
  @override
  Future<void> call(Effect effect, MsgEmitter<Msg> emit) async {
    return handle(effect, emit);
  }
}
