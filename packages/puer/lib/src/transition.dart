/// Represents a single state transition in a feature.
///
/// A transition captures the complete picture of a state change:
/// - `stateBefore`: The state before processing the message.
/// - `message`: The message that triggered this transition.
/// - `stateAfter`: The new state after processing the message, or `null` if the state did not change.
/// - `effects`: The list of side effects produced during this transition. Can be empty.
///
/// Transitions are emitted through the `Feature.transitions` stream for every message
/// processed by the feature, regardless of whether the state actually changed.
///
/// ### Example:
/// ```dart
/// feature.transitions.listen((transition) {
///   print('Message: ${transition.message}');
///   print('State changed: ${transition.stateAfter != null}');
///   print('Effects: ${transition.effects.length}');
/// });
/// ```
typedef Transition<State, Message, Effect> = ({
  State stateBefore,
  Message message,
  State? stateAfter,
  List<Effect> effects,
});
