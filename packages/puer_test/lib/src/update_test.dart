import 'package:meta/meta.dart';
import 'package:puer/puer.dart';
import 'package:test/test.dart';

/// A testing extension for the [Update] function type.
///
/// This extension provides a utility method to test the behavior of an [Update] function
/// by verifying the resulting state and effects in response to a given state and message.
///
/// ### Usage:
/// Use this extension in your test cases to validate the correctness of the state transition logic
/// and the effects emitted by your [Update] function.
///
/// Example:
/// ```dart
/// Next<MyState, MyEffect> update(MyState state, MyMessage message) {
///   // your logic
/// }
///
/// update.test(
///   state: MyState.initial(),
///   message: MyMessage.update(),
///   expectedState: MyState.updated(),
///   expectedEffects: [MyEffect.doSomething()],
/// );
/// ```
@experimental
extension UpdateTest<State, Msg, Effect> on Update<State, Msg, Effect> {
  /// Tests the behavior of an [Update] function by verifying the resulting
  /// state and effects.
  ///
  /// - [state]: The initial state before the update.
  /// - [message]: The message triggering the update.
  /// - [expectedState]: The expected state after the update. Can be `null` to signify no state change.
  /// - [expectedEffects]: A list of expected effects emitted by the update. Defaults to an empty list.
  ///
  /// This method compares the actual state and effects returned by the update
  /// to the expected values using the `expect` matcher.
  void test({
    required State state,
    required Msg message,
    State? expectedState,
    List<Effect> expectedEffects = const [],
  }) {
    final (actualState, actualEffects) = this(state, message);
    expect(actualState, expectedState);
    if (expectedEffects.isEmpty) {
      expect(actualEffects, isEmpty);
    } else {
      expect(actualEffects, containsAllInOrder(expectedEffects));
    }
  }
}
