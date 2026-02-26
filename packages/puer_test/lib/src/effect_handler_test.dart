import 'package:meta/meta.dart';
import 'package:puer/puer.dart';
import 'package:test/test.dart';

/// A testing extension for [EffectHandler].
///
/// This extension provides a utility method to simplify and standardize the testing
/// of effect handlers by verifying the messages emitted in response to a given effect.
///
/// ### Usage:
/// Use this extension in your test cases to validate the behavior of
/// your [EffectHandler] implementation. Pass the effect to be tested
/// and optionally specify the expected emitted messages.
///
/// Example:
/// ```dart
/// final handler = MyEffectHandler();
/// await handler.test(
///   effect: MyEffect(),
///   expectedMessages: [MyMsg.success(), MyMsg.done()],
/// );
/// ```
@experimental
extension EffectHandlerTests<Effect, Message>
    on EffectHandler<Effect, Message> {
  /// Tests the behavior of the [EffectHandler] by verifying
  /// the messages it emits in response to the given [effect].
  ///
  /// - [effect]: The effect to be processed by the handler.
  /// - [expectedMessages]: An optional list of messages expected to be emitted
  ///   by the handler. If null, the test will verify that no messages are emitted.
  ///
  /// This method collects emitted messages and asserts their order against
  /// the [expectedMessages] using the `containsAllInOrder` matcher. If
  /// [expectedMessages] is not provided, it asserts that no messages are emitted.
  Future<void> test({
    required Effect effect,
    Iterable<Message> expectedMessages = const [],
  }) async {
    final actual = <Message>[];
    await call(effect, actual.add);
    if (expectedMessages.isEmpty) {
      expect(actual, isEmpty);
    } else {
      expect(actual, containsAllInOrder(expectedMessages));
    }
  }
}
