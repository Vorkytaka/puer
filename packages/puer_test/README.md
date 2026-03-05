# Puer Test

<p align="center">
<img src="https://raw.githubusercontent.com/Vorkytaka/puer/master/media/images/logo.png" height="200" alt="Puer" />
</p>

<p align="center">
<a href="https://pub.dev/packages/puer_test"><img src="https://img.shields.io/pub/v/puer_test.svg" alt="Pub"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Testing utilities for [puer](https://pub.dev/packages/puer) — concise, assertion-style tests for `update` functions and `EffectHandler`s.

---

## Features

✅ **Concise update tests** — Test your pure `update` function with a single `.test()` call  
✅ **Handler testing** — Verify effect handlers emit the correct messages  
✅ **No boilerplate** — No manual stream subscriptions, no async coordination  
✅ **Clear assertions** — Expected state and effects are explicit parameters

---

## Installation

```yaml
dev_dependencies:
  puer_test: ^1.0.0-alpha.1
```

---

## Testing `update` functions

Since `update` is a pure function, testing is straightforward — call it with a state and message, verify the result.

**Example:**

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

  test('LoadTodos sets loading flag and emits FetchTodos effect', () {
    todoUpdate.test(
      state: const TodoState(todos: [], isLoading: false),
      message: LoadTodos(),
      expectedState: const TodoState(todos: [], isLoading: true),
      expectedEffects: [FetchTodos()],
    );
  });
}
```

**Parameters:**

| Parameter | Description |
|---|---|
| `state` | The current state before the message |
| `message` | The message to process |
| `expectedState` | The expected state after processing (optional if no state change) |
| `expectedEffects` | The expected list of effects (optional if no effects) |

---

## Testing `EffectHandler`s

Effect handlers require mocks for their dependencies. This example uses [mocktail](https://pub.dev/packages/mocktail).

**Example:**

```dart
import 'package:mocktail/mocktail.dart';
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  test('FetchTodosHandler emits TodosLoaded on success', () async {
    final mockRepo = MockTodoRepository();
    when(() => mockRepo.fetchAll()).thenAnswer(
      (_) async => ['Task 1', 'Task 2'],
    );

    final handler = FetchTodosHandler(mockRepo);

    await handler.test(
      effect: FetchTodos(),
      expectedMessages: [TodosLoaded(['Task 1', 'Task 2'])],
    );
  });

  test('FetchTodosHandler emits TodosLoadFailed on error', () async {
    final mockRepo = MockTodoRepository();
    when(() => mockRepo.fetchAll()).thenThrow(Exception('Network error'));

    final handler = FetchTodosHandler(mockRepo);

    await handler.test(
      effect: FetchTodos(),
      expectedMessages: [TodosLoadFailed()],
    );
  });
}
```

**Parameters:**

| Parameter | Description |
|---|---|
| `effect` | The effect to process |
| `expectedMessages` | The expected list of messages emitted by the handler |

---

## Why test with puer_test?

**Without puer_test:**

```dart
test('Increment increases count', () {
  final result = counterUpdate(
    const CounterState(count: 5),
    Increment(),
  );
  
  expect(result.state, equals(const CounterState(count: 6)));
  expect(result.effects, isEmpty);
});
```

**With puer_test:**

```dart
test('Increment increases count', () {
  counterUpdate.test(
    state: const CounterState(count: 5),
    message: Increment(),
    expectedState: const CounterState(count: 6),
  );
});
```

Less noise, clearer intent.

---

## Learn more

- **[puer](https://pub.dev/packages/puer)** — Core state management library
- **[Full documentation](https://github.com/Vorkytaka/puer)** — Testing guide, patterns, examples

---

## License

[MIT](https://github.com/Vorkytaka/puer/blob/master/LICENSE)
