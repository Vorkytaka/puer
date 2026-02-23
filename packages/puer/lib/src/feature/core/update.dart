part of 'feature.dart';

/// Represents the result of handling a message with the update function.
///
/// - [State]: The new state to transition to. If `null`, no state change occurs.
/// - [List<Effect>]: A list of side effects to execute after processing the message.
@experimental
typedef Next<State, Effect> = (State?, List<Effect>);

/// A helper function for constructing a [Next] result.
///
/// This function simplifies the process of returning the next state and side effects.
/// Instead of writing `return (null, const []);`, you can use: `return next();`
///
/// - [state]: The next state, or `null` to indicate no state change.
/// - [effects]: A list of side effects to execute. Defaults to an empty list.
@experimental
@pragma('vm:prefer-inline')
(State?, List<Effect>) next<State, Effect>({
  State? state,
  List<Effect> effects = const [],
}) =>
    (state, effects);

/// A pure function type that updates the state in response to a message.
///
/// - [State]: The type representing the feature's state.
/// - [Msg]: The type representing messages that trigger state changes.
/// - [Effect]: The type of side effects triggered during the update.
///
/// This function takes the current state and an incoming message, then returns a [Next]
/// record containing the new state and any effects to execute.
///
/// The main idea is that this function __must__ be pure.
/// If it's not, you might want to look at other state managers. :)
@experimental
typedef Update<State, Msg, Effect> = Next<State, Effect> Function(
  State state,
  Msg message,
);

/// Interface for implementing the update function.
///
/// Provides a callable structure for state updates, mirroring the functionality
/// of the [Update] typedef with an object-oriented design. But you better does not use it.
///
/// - [State]: The type representing the feature's state.
/// - [Msg]: The type representing messages that trigger state changes.
/// - [Effect]: The type of side effects triggered during the update.
@experimental
abstract interface class IUpdate<State, Msg, Effect> {
  /// Processes the current [state] and an incoming [message].
  ///
  /// Returns a [Next] object containing the new state (if any) and a list of effects to execute.
  Next<State, Effect> call(State state, Msg message);
}
