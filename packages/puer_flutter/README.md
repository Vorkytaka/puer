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
  puer: ^1.0.0-alpha.1
  puer_flutter: ^1.0.0-alpha.1
```

---

## Quick Example

```dart
import 'package:flutter/material.dart';
import 'package:puer/puer.dart';
import 'package:puer_flutter/puer_flutter.dart';

// Your feature types
typedef CounterFeature = Feature<CounterState, CounterMessage, Never>;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureProvider<CounterFeature>.create(
        create: (context) => Feature<CounterState, CounterMessage, Never>(
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
  create: (context) => Feature<CounterState, CounterMessage, Never>(
    initialState: const CounterState(count: 0),
    update: counterUpdate,
  ),
  child: const MyWidget(),
)
```

**Value mode** — Provides an existing feature:

```dart
final feature = Feature<CounterState, CounterMessage, Never>(
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

#### Parameters

- **`create`** (create mode): Factory function to create the feature
- **`value`** (value mode): Existing feature instance
- **`child`**: Widget subtree that has access to the feature
- **`lazy`**: If `true`, delays feature creation until first access (default: `false`)

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

#### Parameters

- **`builder`** (required): Function that builds UI from state — `(BuildContext, State) → Widget`
- **`feature`**: Custom feature instance (if `null`, resolves from `FeatureProvider`)
- **`buildWhen`**: Optional filter — `(previous, current) → bool`. If returns `false`, UI won't rebuild

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

#### Parameters

- **`listener`** (required): Callback invoked on state changes — `(BuildContext, State) → void`
- **`child`** (required): Widget to render
- **`feature`**: Custom feature instance (if `null`, resolves from `FeatureProvider`)
- **`listenWhen`**: Optional filter — `(previous, current) → bool`. If returns `false`, listener won't be called

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

#### Parameters

- **`selector`** (required): Function that extracts a value from state — `(State) → T`
- **`builder`** (required): Function that builds UI from selected value — `(BuildContext, T) → Widget`
- **`feature`**: Custom feature instance (if `null`, resolves from `FeatureProvider`)

#### Why use FeatureSelector?

**Without FeatureSelector:**

```dart
FeatureBuilder<TodoFeature, TodoState>(
  builder: (context, state) {
    return Text('Completed: ${state.completedCount}');
  },
)
// Rebuilds whenever ANY part of TodoState changes
```

**With FeatureSelector:**

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

#### Parameters

- **`listener`** (required): Callback invoked when effect is emitted — `(BuildContext, Effect) → void`
- **`child`** (required): Widget to render
- **`feature`**: Custom feature instance (if `null`, resolves from `FeatureProvider`)

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
// ❌ BAD: Navigation in EffectHandler
final class NavigateHandler implements EffectHandler<Effect, Message> {
  const NavigateHandler(this._navigator);  // ❌ Passing BuildContext/Navigator is awkward
  
  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    switch (effect) {
      case NavigateToHome():
        _navigator.pushNamed('/home');  // ❌ Hard to test
    }
  }
}

// ✅ GOOD: Navigation in FeatureEffectListener
FeatureEffectListener<MyFeature, MyEffect, NavigateToHome>(
  listener: (context, effect) {
    Navigator.of(context).pushNamed('/home');  // ✅ Simple, testable state logic
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
      // This runs once when isAuthenticated becomes true
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

## Learn More

- **[puer package](https://pub.dev/packages/puer)** — Core library documentation
- **[Main repository](https://github.com/Vorkytaka/puer)** — Full architecture guide, patterns, and examples
- **[The Elm Architecture](https://guide.elm-lang.org/architecture/)** — The pattern puer is based on

---

## License

[MIT](https://github.com/Vorkytaka/puer/blob/master/LICENSE)
