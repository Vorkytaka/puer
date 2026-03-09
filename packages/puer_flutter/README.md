# Puer Flutter

<p align="center">
<img src="https://raw.githubusercontent.com/Vorkytaka/puer/master/media/images/logo.png" height="200" alt="Puer" />
</p>

<p align="center">
<a href="https://pub.dev/packages/puer_flutter"><img src="https://img.shields.io/pub/v/puer_flutter.svg" alt="Pub"></a>
<a href="https://github.com/Vorkytaka/puer/actions"><img src="https://github.com/Vorkytaka/puer/actions/workflows/validate_repository.yml/badge.svg" alt="CI"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Flutter widgets for **[puer](https://pub.dev/packages/puer)** — a reactive, functional state management library based on The Elm Architecture.

This package provides five essential widgets to integrate your puer features into Flutter apps:

- **`FeatureProvider`** — Exposes a feature to the widget tree
- **`FeatureBuilder`** — Rebuilds UI when state changes
- **`FeatureListener`** — Executes side effects in response to state changes
- **`FeatureSelector`** — Rebuilds UI only when a specific part of state changes
- **`FeatureEffectListener`** — Handles effects in the UI layer (navigation, dialogs, etc.)

---

## Installation

Add `puer_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  puer_flutter: ^1.0.0-alpha.1
```

**Note:** `puer_flutter` re-exports the core `puer` package, so you only need this single dependency.

---

## Quick Example

```dart
import 'package:flutter/material.dart';
import 'package:puer_flutter/puer_flutter.dart';

// Your feature types
typedef CounterFeature = Feature<CounterState, CounterMessage, CounterEffect>;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureProvider<CounterFeature>.create(
        create: (context) => Feature<CounterState, CounterMessage, CounterEffect>(
          initialState: const CounterState(count: 0),
          update: counterUpdate,
        ),
        child: const CounterPage(),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = FeatureProvider.of<CounterFeature>(context);

    return Scaffold(
      body: Center(
        child: FeatureBuilder<CounterFeature, CounterState>(
          builder: (context, state) => Text(
            '${state.count}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => feature.accept(Increment()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Widgets

### 1. FeatureProvider

**Purpose:** Provides a `Feature` instance to the widget tree and manages its lifecycle.

**When to use:** Wrap your app or screen in a `FeatureProvider` to make a feature available to descendant widgets.

#### Usage

**Create mode** — Creates and initializes a feature:

```dart
FeatureProvider<CounterFeature>.create(
  create: (context) => Feature<CounterState, CounterMessage, CounterEffect>(
    initialState: const CounterState(count: 0),
    update: counterUpdate,
  ),
  child: const MyWidget(),
)
```

**Value mode** — Provides an existing feature:

```dart
final feature = Feature<CounterState, CounterMessage, CounterEffect>(
  initialState: const CounterState(count: 0),
  update: counterUpdate,
);

FeatureProvider<CounterFeature>.value(
  value: feature,
  child: const MyWidget(),
)
```

**Retrieve the feature:**

```dart
final feature = FeatureProvider.of<CounterFeature>(context);
feature.accept(Increment());
```

#### Lifecycle

- **Create mode**: Automatically calls `feature.init()` when the widget enters the tree and `feature.dispose()` when it leaves
- **Value mode**: Does not manage lifecycle — you must call `init()` and `dispose()` manually

---

### 2. FeatureBuilder

**Purpose:** Rebuilds UI when the feature's state changes.

**When to use:** When you need to display state values in your UI.

#### Usage

```dart
FeatureBuilder<CounterFeature, CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

**With custom feature instance:**

```dart
FeatureBuilder<CounterFeature, CounterState>(
  feature: myFeatureInstance,
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

**Filter rebuilds with `buildWhen`:**

```dart
FeatureBuilder<CounterFeature, CounterState>(
  buildWhen: (previous, current) {
    // Only rebuild when count is even
    return current.count % 2 == 0;
  },
  builder: (context, state) {
    return Text('Even count: ${state.count}');
  },
)
```

---

### 3. FeatureListener

**Purpose:** Executes side effects (navigation, dialogs, snackbars) in response to state changes **without rebuilding UI**.

**When to use:** When you need to perform one-time actions based on state changes, not display state values.

#### Usage

```dart
FeatureListener<AuthFeature, AuthState>(
  listener: (context, state) {
    if (state.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: const LoginForm(),
)
```

**Filter when to listen:**

```dart
FeatureListener<TodoFeature, TodoState>(
  listenWhen: (previous, current) {
    // Only listen when error changes
    return previous.error != current.error;
  },
  listener: (context, state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    }
  },
  child: const TodoList(),
)
```

#### Common Use Cases

- **Navigation**: Push/pop routes when state changes
- **Dialogs**: Show/hide dialogs based on state
- **Snackbars**: Display messages on errors or success
- **Analytics**: Track state transitions

---

### 4. FeatureSelector

**Purpose:** Rebuilds UI only when a **specific part** of state changes, optimizing performance.

**When to use:** When you only care about a subset of state and want to avoid unnecessary rebuilds.

#### Usage

```dart
FeatureSelector<TodoFeature, TodoState, int>(
  selector: (state) => state.completedCount,
  builder: (context, completedCount) {
    return Text('Completed: $completedCount');
  },
)
```

**Complex selection:**

```dart
FeatureSelector<UserFeature, UserState, UserProfile?>(
  selector: (state) => state.user?.profile,
  builder: (context, profile) {
    if (profile == null) return const CircularProgressIndicator();
    return Text('Welcome, ${profile.name}!');
  },
)
```

#### Why use FeatureSelector?

Consider a small `TodoState` with several independent fields — UI that displays only the completed count should not rebuild when unrelated fields change:

```dart
final class TodoState {
  const TodoState({
    required this.todos,
    required this.completedCount,
    required this.isLoading,
    this.error,
  });

  final List<String> todos;
  final int completedCount;
  final bool isLoading;
  final String? error;
}
```

Without FeatureSelector (using `FeatureBuilder`) the widget rebuilds when ANY field on `TodoState` changes:

```dart
FeatureBuilder<TodoFeature, TodoState>(
  builder: (context, state) {
    return Text('Completed: ${state.completedCount}');
  },
)
// Rebuilds whenever ANY part of TodoState changes (todos, isLoading, error, etc.)
```

With FeatureSelector you pick a specific field — here `completedCount` — so the widget rebuilds only when that value changes:

```dart
FeatureSelector<TodoFeature, TodoState, int>(
  selector: (state) => state.completedCount,
  builder: (context, completedCount) {
    return Text('Completed: $completedCount');
  },
)
// Rebuilds ONLY when completedCount changes
```

---

### 5. FeatureEffectListener

**Purpose:** Listens to **effects** emitted by the feature and performs UI-related side effects.

**When to use:** When effects need to trigger UI actions (navigation, dialogs, snackbars) that cannot be handled in `EffectHandler`.

#### Usage

```dart
sealed class TodoEffect {}
final class ShowSuccessMessage extends TodoEffect {
  const ShowSuccessMessage(this.message);
  final String message;
}
final class NavigateToDetail extends TodoEffect {
  const NavigateToDetail(this.todoId);
  final String todoId;
}

// In your widget tree:
FeatureEffectListener<TodoFeature, TodoEffect, ShowSuccessMessage>(
  listener: (context, effect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(effect.message)),
    );
  },
  child: FeatureEffectListener<TodoFeature, TodoEffect, NavigateToDetail>(
    listener: (context, effect) {
      Navigator.of(context).pushNamed('/todo/${effect.todoId}');
    },
    child: const TodoList(),
  ),
)
```

#### When to use EffectHandler vs FeatureEffectListener

| Use `EffectHandler` | Use `FeatureEffectListener` |
|---|---|
| Business logic side effects (HTTP, storage, timers) | UI-only side effects (navigation, dialogs, snackbars) |
| Testable with mocks | Depends on Flutter context |
| Returns messages to feature | No return value |
| Lives in feature setup | Lives in widget tree |

**Example:**

```dart
// ✅ EffectHandler: HTTP call (business logic)
sealed class TodoEffect {}
final class FetchTodos extends TodoEffect {}

final class FetchTodosHandler implements EffectHandler<TodoEffect, TodoMessage> {
  @override
  Future<void> call(TodoEffect effect, MsgEmitter<TodoMessage> emit) async {
    switch (effect) {
      case FetchTodos():
        final todos = await repository.fetchTodos();
        emit(TodosLoaded(todos));
    }
  }
}

// ✅ FeatureEffectListener: Navigation (UI)
sealed class TodoEffect {}
final class NavigateToDetail extends TodoEffect {
  const NavigateToDetail(this.todoId);
  final String todoId;
}

FeatureEffectListener<TodoFeature, TodoEffect, NavigateToDetail>(
  listener: (context, effect) {
    Navigator.of(context).pushNamed('/todo/${effect.todoId}');
  },
  child: const TodoList(),
)
```

---

## Combining Widgets

You can compose widgets to handle both state changes and effects:

```dart
FeatureProvider<TodoFeature>.create(
  create: (context) => todoFeature,
  child: FeatureListener<TodoFeature, TodoState>(
    listenWhen: (previous, current) => previous.error != current.error,
    listener: (context, state) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    },
    child: FeatureEffectListener<TodoFeature, TodoEffect, NavigateToDetail>(
      listener: (context, effect) {
        Navigator.of(context).pushNamed('/todo/${effect.todoId}');
      },
      child: FeatureBuilder<TodoFeature, TodoState>(
        builder: (context, state) {
          if (state.isLoading) return const CircularProgressIndicator();
          return TodoList(todos: state.todos);
        },
      ),
    ),
  ),
)
```

---

## Best Practices

### 1. Define a feature typedef

Reduces verbosity when declaring widget types:

```dart
typedef CounterFeature = Feature<CounterState, CounterMessage, CounterEffect>;

// Instead of:
FeatureBuilder<Feature<CounterState, CounterMessage, CounterEffect>, CounterState>(...)

// Use:
FeatureBuilder<CounterFeature, CounterState>(...)
```

### 2. Use FeatureSelector for performance

When displaying a small part of a large state object:

```dart
// ❌ BAD: Rebuilds on ANY state change
FeatureBuilder<UserFeature, UserState>(
  builder: (context, state) => Text(state.user.name),
)

// ✅ GOOD: Rebuilds ONLY when name changes
FeatureSelector<UserFeature, UserState, String>(
  selector: (state) => state.user.name,
  builder: (context, name) => Text(name),
)
```

### 3. Keep UI side effects in FeatureEffectListener

Navigation, dialogs, and snackbars should be handled in the UI layer, not in `EffectHandler`:

```dart
// ✅ GOOD: Navigation in FeatureEffectListener
FeatureEffectListener<MyFeature, MyEffect, NavigateToHome>(
  listener: (context, effect) {
    Navigator.of(context).pushNamed('/home');
  },
  child: const MyWidget(),
)
```

### 4. Use FeatureListener for one-time UI actions

When you need to respond to state changes without rebuilding UI:

```dart
FeatureListener<AuthFeature, AuthState>(
  listener: (context, state) {
    if (state.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: const LoginPage(),
)
```

### 5. Filter rebuilds with buildWhen and listenWhen

Avoid unnecessary work by filtering state changes:

```dart
FeatureBuilder<TodoFeature, TodoState>(
  buildWhen: (previous, current) {
    // Only rebuild when todos list changes, ignore loading flag
    return previous.todos != current.todos;
  },
  builder: (context, state) => TodoList(todos: state.todos),
)
```

---

## Packages

| Package | Pub | Description |
|---------|-----|-------------|
| [**puer**](https://github.com/Vorkytaka/puer/tree/master/packages/puer) | [![pub package](https://img.shields.io/pub/v/puer.svg)](https://pub.dev/packages/puer) | Core TEA implementation with `Feature`, `update`, and effect handlers. Pure Dart foundation. |
| [**puer_flutter**](https://github.com/Vorkytaka/puer/tree/master/packages/puer_flutter) | [![pub package](https://img.shields.io/pub/v/puer_flutter.svg)](https://pub.dev/packages/puer_flutter) | Flutter integration: `FeatureProvider`, `FeatureBuilder`, `FeatureListener` widgets. |
| [**puer_effect_handlers**](https://github.com/Vorkytaka/puer/tree/master/packages/puer_effect_handlers) | [![pub package](https://img.shields.io/pub/v/puer_effect_handlers.svg)](https://pub.dev/packages/puer_effect_handlers) | Composable wrappers for debouncing, sequential execution, and isolate offloading. |
| [**puer_test**](https://github.com/Vorkytaka/puer/tree/master/packages/puer_test) | [![pub package](https://img.shields.io/pub/v/puer_test.svg)](https://pub.dev/packages/puer_test) | Testing utilities for concise update and handler tests. Add to `dev_dependencies`. |
| [**puer_time_travel**](https://github.com/Vorkytaka/puer/tree/master/packages/puer_time_travel) | [![pub package](https://img.shields.io/pub/v/puer_time_travel.svg)](https://pub.dev/packages/puer_time_travel) | Time-travel debugging with DevTools extension. Use in debug builds to inspect history. |

---

## Learn More

- **[Main repository](https://github.com/Vorkytaka/puer)** — Full architecture guide, patterns, and examples
- **[The Elm Architecture](https://guide.elm-lang.org/architecture/)** — The pattern puer is based on

---

## License

[MIT](https://github.com/Vorkytaka/puer/blob/master/LICENSE)
