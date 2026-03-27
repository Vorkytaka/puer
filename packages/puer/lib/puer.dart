/// A clean and predictable state management library inspired by The Elm Architecture.
///
/// Puer provides a unidirectional data flow model built around three core
/// primitives:
///
/// - **State** — an immutable snapshot of your feature's current condition.
/// - **Message** — a plain value describing something that happened.
/// - **Effect** — a plain value describing a side effect to perform (HTTP call,
///   storage write, navigation, etc.). Effects are executed by `EffectHandler`s
///   and are completely decoupled from business logic.
///
/// The central piece is `Feature`, which wires all three together: it holds the
/// current state, routes incoming messages through your pure `Update`
/// function, and dispatches effects to the registered handlers.
///
/// ## Quick start
///
/// ```dart
/// import 'package:puer/puer.dart';
///
/// // 1. Define State, Message (and optionally Effect) types.
/// final class CounterState { const CounterState(this.count); final int count; }
/// sealed class CounterMsg {}
/// final class Increment extends CounterMsg {}
///
/// // 2. Write a pure update function.
/// Next<CounterState, Never> counterUpdate(CounterState s, CounterMsg m) =>
///     switch (m) { Increment() => next(state: CounterState(s.count + 1)) };
///
/// // 3. Create and use the feature.
/// void main() {
///   final feature = Feature<CounterState, CounterMsg, Never>(
///     initialState: const CounterState(0),
///     update: counterUpdate,
///   );
///   feature.init();
///   feature.add(Increment());
///   print(feature.state.count); // 1
///   feature.dispose();
/// }
/// ```
///
/// See also:
/// - `Feature` — the main entry point.
/// - `ReadOnlyFeature` — a read-only view of a feature.
/// - `EffectHandler` — the contract for executing side effects.
/// - `Update` — the pure function type alias.
/// - `Next` / `next` — helpers for constructing update results.
/// - `Transition` — the record emitted on every state change.
library;

export 'src/disposable.dart';
export 'src/effect_handler.dart';
export 'src/feature.dart';
export 'src/read_only_feature.dart';
export 'src/state_stream.dart';
export 'src/transition.dart';
export 'src/update.dart';
