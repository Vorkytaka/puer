<p align="center">
<img src="https://raw.githubusercontent.com/Vorkytaka/puer/master/media/images/logo.png" height="100" alt="Puer" />
</p>

<p align="center">
<a href="https://pub.dev/packages/puer"><img src="https://img.shields.io/pub/v/puer.svg" alt="Pub"></a>
<a href="https://github.com/Vorkytaka/puer/actions"><img src="https://github.com/Vorkytaka/puer/actions/workflows/validate_repository.yml/badge.svg" alt="CI"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

A clean and predictable state management solution inspired by **The Elm Architecture**.

Business logic as pure functions. Side effects as explicit data. Unidirectional data flow.

---

## Features

✅ **Pure `update` function** — `(State, Message) → (State?, List<Effect>)`. Synchronous, deterministic, testable without mocks  
✅ **Effects as data** — Side effects are plain values. `EffectHandler`s execute them separately from logic  
✅ **Unidirectional flow** — One way to change state: send a `Message`  
✅ **Full traceability** — Every state change is caused by a message and recorded in `transitions`  
✅ **Pure Dart** — No Flutter dependency. Works in CLI tools, backend services, and Flutter apps  
✅ **Time-travel ready** — Drop-in support via `puer_time_travel` package

---

## Quick example

```dart
import 'package:puer/puer.dart';

// State: just data
final class CounterState {
  const CounterState({required this.count});
  final int count;
}

// Messages: sealed class for exhaustive handling
sealed class CounterMessage {}
final class Increment extends CounterMessage {}
final class Decrement extends CounterMessage {}

// Update: pure function (State, Message) → (State?, Effects)
Next<CounterState, Never> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      Increment() => next(state: CounterState(count: state.count + 1)),
      Decrement() => next(state: CounterState(count: state.count - 1)),
    };

// Create feature and use it
void main() {
  final feature = Feature<CounterState, CounterMessage, Never>(
    initialState: const CounterState(count: 0),
    update: counterUpdate,
  );

  feature.init();

  print(feature.state.count); // 0
  feature.accept(Increment());
  print(feature.state.count); // 1

  feature.dispose();
}
```

---

## Core concepts

| Concept | Description |
|---------|-------------|
| **State** | Immutable data representing your feature's current state |
| **Message** | A value describing something that happened (event, intent) |
| **Update** | Pure function `(State, Message) → (State?, List<Effect>)` |
| **Effect** | Plain data describing a side effect to perform (HTTP call, storage, etc.) |
| **EffectHandler** | Executes effects asynchronously and emits messages back |
| **Feature** | Wires everything together: holds state, runs update, dispatches effects |

---

## Adding side effects

When you need async work (HTTP, storage, timers), return an `Effect` from `update` and handle it separately:

```dart
// Effect types
sealed class CounterEffect {}
final class SaveCount extends CounterEffect {
  const SaveCount(this.count);
  final int count;
}

// Update now returns effects
Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      Increment() => next(
          state: CounterState(count: state.count + 1),
          effects: [SaveCount(state.count + 1)],
        ),
      Decrement() => next(
          state: CounterState(count: state.count - 1),
          effects: [SaveCount(state.count - 1)],
        ),
    };

// Handler performs the actual async work
final class SaveCountHandler
    implements EffectHandler<CounterEffect, CounterMessage> {
  const SaveCountHandler(this._storage);
  final CounterStorage _storage;

  @override
  Future<void> call(
    CounterEffect effect,
    MsgEmitter<CounterMessage> emit,
  ) async {
    switch (effect) {
      case SaveCount(:final count):
        await _storage.saveCount(count);
        // Fire-and-forget: no message emitted back
    }
  }
}

// Register the handler
final feature = Feature<CounterState, CounterMessage, CounterEffect>(
  initialState: const CounterState(count: 0),
  update: counterUpdate,
  effectHandlers: [SaveCountHandler(storage)],
);
```

**Key insight:** `update` stays pure and testable. Async work happens in handlers, which are tested separately.

---

## Ecosystem

This package is the pure-Dart core. Integrate it with these companion packages:

| Package | Description | pub.dev |
|---------|-------------|---------|
| **puer_flutter** | Flutter widgets: `FeatureProvider`, `FeatureBuilder`, `FeatureListener` | [pub.dev](https://pub.dev/packages/puer_flutter) |
| **puer_test** | Test utilities: concise `.test()` extensions for `update` and handlers | [pub.dev](https://pub.dev/packages/puer_test) |
| **puer_time_travel** | Drop-in `TimeTravelFeature` with history navigation and DevTools | [pub.dev](https://pub.dev/packages/puer_time_travel) |
| **puer_effect_handlers** | Composable wrappers: debounce, sequential, isolate, adapters | *coming soon* |

---

## Why pure functions and explicit effects?

**Testability:** Test your entire business logic with synchronous function calls. No mocks, no async coordination, no flakiness.

```dart
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

void main() {
  test('Increment increases count by 1', () {
    counterUpdate.test(
      state: const CounterState(count: 5),
      message: Increment(),
      expectedState: const CounterState(count: 6),
    );
  });
}
```

**Traceability:** Every state change is caused by a message. Your `transitions` stream shows the complete flow:

```dart
Transition {
  before: CounterState(count: 5),
  message: Increment(),
  after: CounterState(count: 6),
  effects: [SaveCount(6)]
}
```

**Predictability:** Given the same state and message, `update` always returns the same result. No hidden behavior, no surprises.

---

## When to use puer

**Good fit:**
- Features with non-trivial business logic that must be unit-tested
- Need for explicit, traceable, independently-testable side effects
- Value in Elm/MVI mental model: one state, one way to change it
- Time-travel debugging is valuable
- Composable effect-execution policies (debounce, sequencing, etc.)

**Not the right fit:**
- Small apps with minimal logic (overhead not worth it)
- Teams new to Dart/Flutter (adds conceptual complexity)
- Simple local UI state (use `setState` or `ValueNotifier`)

---

## Learn more

- **[Full documentation](https://github.com/Vorkytaka/puer)** — Architecture guide, patterns, best practices
- **[The Elm Architecture](https://guide.elm-lang.org/architecture/)** — The pattern puer is based on
- **[Examples](https://github.com/Vorkytaka/puer/tree/master/examples)** — Counter, todos, async flows

---

## License

[MIT](https://github.com/Vorkytaka/puer/blob/master/LICENSE)
