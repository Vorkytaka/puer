/// Testing utilities for puer — concise, assertion-style tests for
/// `update` functions and `EffectHandler`s.
///
/// This library provides extension methods that make testing puer features
/// straightforward and readable:
///
/// - `.test()` on update functions to verify state transitions and effects
/// - `.test()` on effect handlers to verify message emissions
///
/// Example:
/// ```dart
/// import 'package:puer_test/puer_test.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   test('Increment increases count', () {
///     counterUpdate.test(
///       state: const CounterState(count: 5),
///       message: Increment(),
///       expectedState: const CounterState(count: 6),
///     );
///   });
/// }
/// ```
library;

export 'src/effect_handler_test.dart';
export 'src/update_test.dart';
