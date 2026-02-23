part of 'feature.dart';

/// A function type for emitting messages within effect handlers.
///
/// Used to trigger messages that may influence state changes or cause further effects.
@experimental
typedef MsgEmitter<Msg> = void Function(Msg message);

/// Interface for emitting messages.
///
/// This provides a callable structure to trigger messages, offering a more abstract
/// alternative to [MsgEmitter].
@experimental
abstract interface class IMsgEmitter<Msg> {
  /// Emits the specified [message].
  void call(Msg message);
}

/// Interface for handling effects.
///
/// Defines the contract for processing effects and emitting messages as a result.
/// Effect handlers allow for side effects, such as API calls or logging, without
/// directly modifying the state.
///
/// - [Effect]: The type of effects this handler processes.
/// - [Msg]: The type of messages this handler can emit.
@experimental
abstract interface class EffectHandler<Effect, Msg> {
  /// Processes the given [effect] and optionally emits messages using [emit].
  ///
  /// This method may execute asynchronously or synchronously, depending on the effect's nature.
  /// - [effect]: The effect to process.
  /// - [emit]: A function to emit messages in response to the effect.
  FutureOr<void> call(Effect effect, MsgEmitter<Msg> emit);
}

/// A functional representation of an effect handler.
///
/// Equivalent to [EffectHandler] but defined as a function type for simpler usage.
/// - [Effect]: The type of effects handled.
/// - [Msg]: The type of messages emitted.
@experimental
typedef FunEffectHandler<Effect, Msg> = FutureOr<void> Function(
  Effect effect,
  MsgEmitter<Msg> emit,
);
