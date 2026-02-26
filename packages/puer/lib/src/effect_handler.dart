import 'dart:async';

import 'package:meta/meta.dart';

/// A function type for emitting messages within effect handlers.
///
/// Used to trigger messages that may influence state changes or cause further effects.
@experimental
typedef MsgEmitter<Message> = void Function(Message message);

/// Interface for handling effects.
///
/// Defines the contract for processing effects and emitting messages as a result.
/// Effect handlers allow for side effects, such as API calls or logging, without
/// directly modifying the state.
///
/// - [Effect]: The type of effects this handler processes.
/// - [Message]: The type of messages this handler can emit.
@experimental
abstract interface class EffectHandler<Effect, Message> {
  /// Processes the given [effect] and optionally emits messages using [emit].
  ///
  /// This method may execute asynchronously or synchronously, depending on the effect's nature.
  /// - [effect]: The effect to process.
  /// - [emit]: A function to emit messages in response to the effect.
  FutureOr<void> call(Effect effect, MsgEmitter<Message> emit);
}

/// A functional representation of an effect handler.
///
/// Equivalent to [EffectHandler] but defined as a function type for simpler usage.
/// - [Effect]: The type of effects handled.
/// - [Message]: The type of messages emitted.
@experimental
typedef FunEffectHandler<Effect, Message> = FutureOr<void> Function(
  Effect effect,
  MsgEmitter<Message> emit,
);
