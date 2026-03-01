# Puer

A reactive, functional state management library for Dart and Flutter, built on The Elm Architecture — pure business logic, explicit side effects, and predictable unidirectional data flow.

**The Elm Architecture (TEA)** is a functional programming pattern where state updates are pure functions and side effects are represented as explicit data. Puer brings this mental model to Dart and Flutter, enforcing a strict separation between logic (testable, pure) and execution (controlled, traceable).

![Puer logo](media/images/logo.png)

---

## Why puer?

If you have used BLoC, Riverpod, or Provider, you already know the value of structured state management. Puer takes that further by enforcing a strict contract: **business logic is a pure function, side effects are data**.

This separation eliminates entire classes of bugs. Your state transitions are deterministic and testable without mocks. Your side effects are explicit, traceable, and independently verifiable. Your features become predictable state machines instead of tangled webs of async callbacks.

- **Pure `update` function.** Your entire business logic fits into one function: `(State, Message) → (State?, List<Effect>)`. No streams, no async, no hidden dependencies. Given the same inputs it always produces the same output.
- **Effects are first-class values.** Side effects (HTTP calls, navigation, timers) are returned as plain data from `update`. Puer routes them to `EffectHandler`s — logic and execution are never mixed.
- **Testability without mocks.** Because `update` is pure, you can test every state transition with a single function call and no test doubles. Effect handlers are tested independently.
- **Unidirectional data flow.** There is only one way for state to change: a `Message` passes through `update`. No scattered `setState`, no out-of-band mutations.
- **Time-travel debugging.** `TimeTravelFeature` records every message and lets you step backward and forward through your app's history — including a dedicated DevTools extension.
- **Composable effect handlers.** `puer_effect_handlers` (available in this repository, not yet published to pub.dev) ships ready-made wrappers: debounce, sequential execution, type adaptation, and isolate offloading. They compose via extension methods.
- **Minimal Flutter coupling.** The core `puer` package is pure Dart. Flutter integration lives in `puer_flutter` and is optional.

---

## Package overview

| Package | Description | Path |
|---|---|---|
| [`puer`](./packages/puer/) | Core library: `Feature`, `update`, `EffectHandler`, `StateStream`, `Transition`. Pure Dart, no Flutter dependency. | `packages/puer` |
| [`puer_flutter`](./packages/puer_flutter/) | Flutter widgets: `FeatureProvider`, `FeatureBuilder`, `FeatureListener`, `FeatureSelector`, `FeatureEffectListener`. | `packages/puer_flutter` |
| [`puer_effect_handlers`](./packages/puer_effect_handlers/) | Composable handler wrappers: debounce, sequential execution, type adaptation, isolate offloading. Available in this repository. | `packages/puer_effect_handlers` |
| [`puer_test`](./packages/puer_test/) | Test utilities: `UpdateTest` and `EffectHandlerTests` extensions for concise, assertion-style unit tests. | `packages/puer_test` |
| [`puer_time_travel`](./packages/puer_time_travel/) | `TimeTravelFeature` drop-in replacement + `TimeTravelController` for step-by-step history navigation. | `packages/puer_time_travel` |

A typical Flutter app depends on `puer` + `puer_flutter` at runtime, adds `puer_time_travel` in debug builds, and uses `puer_test` in `dev_dependencies`.

---

## When should you use puer?

**Puer is a good fit when:**

- Your features have non-trivial business logic that you want to unit-test as plain functions, without spinning up widgets or mocking streams.
- You want side effects to be explicit, traceable, and independently testable — not hidden inside event handlers or notifier methods.
- Your team finds value in the Elm / MVI mental model: one state per feature, one way to change it.
- You need time-travel debugging for complex, hard-to-reproduce state sequences.
- You want composable effect-execution policies (debounce, sequencing, isolate offloading) without writing them yourself.

**Puer may not be the right fit when:**

- Your app is small or mostly UI-driven with minimal business logic. The overhead of `Feature` + sealed message types is not worthwhile for a few `setState` calls.
- Your team is new to Dart and/or Flutter. The Elm Architecture adds conceptual overhead on top of an already steep learning curve.
- Your project is already deeply invested in BLoC, Riverpod, or another pattern and a migration would outweigh the benefits.
- You need tight framework integration that another library already provides (e.g. Riverpod's code generation, automatic dependency invalidation, or built-in async state).

---

## High-level architecture

Every state change follows the same cycle:

![Data-flow](media/images/data-flow.png)

**Data flow cycle:**

1. A widget (or any code) calls `feature.accept(message)`.
2. `update(currentState, message)` runs **synchronously** and returns a new state and an optional list of effects.
3. If the state changed, `stateStream` emits and widgets rebuild.
4. Each effect is forwarded to every registered `EffectHandler`.
5. Handlers do async work (network, storage, timers) and call `emit(message)` to send new messages **back to the feature** — completing the loop.

---

## Concept glossary

| Term | Description | Also known as |
|---|---|---|
| `Feature` | The central object that holds state, wires update to handlers, and exposes streams. Must call `init()` before use. | Store, ViewModel |
| `State` | An immutable value representing the current state of a feature. Should override `==` and `hashCode` for correct rebuild behavior. | Model |
| `Message` | A value describing something that happened — an event or intent. Use sealed classes for exhaustive switch coverage. | Event, Action, Intent |
| `Update` | A pure function `(State, Message) → (State?, List<Effect>)`. Must be synchronous and deterministic. | Reducer, Reducer function |
| `Effect` | A plain data value that describes a side effect to be performed. Contains no logic, only data. | Command, SideEffect |
| `EffectHandler` | An object that receives an `Effect`, performs async work, and optionally emits new messages. Should be "stupid" — no business logic. | Middleware, Executor, Command handler |
| `View` | Any Flutter widget that reads from `stateStream` and dispatches messages — typically via `FeatureBuilder`. | UI layer |

---

## Everything is data

One of the most powerful principles in puer is that **State, Message, and Effect are just data**. They are plain Dart objects with no behavior, no methods, no logic — just immutable values.

This is not a limitation. It is a superpower.

### Why "just data" matters

When your state, messages, and effects are plain data classes:

1. **Serializable by default.** You can convert them to JSON, save them to disk, send them over the network, or store them in a database. This makes features like offline sync, undo/redo, and crash recovery trivial.

2. **Replayable.** Record a sequence of messages, serialize them, and replay them later to reproduce any bug or test scenario. This is exactly how `TimeTravelFeature` works.

3. **Inspectable.** Tools like DevTools can display the exact state and message history without any special instrumentation. Everything is visible.

4. **Testable without mocks.** Testing `update(state, message)` requires nothing but two plain objects. No dependency injection, no test doubles, no async coordination.

5. **Portable across platforms.** The same state/message/effect types can be shared between Flutter, Dart CLI tools, backend services, and even other languages (via JSON schemas).

### What "just data" means in practice

**✅ Good — Plain data classes:**

```dart
// State: just fields, no methods
final class AuthState {
  const AuthState({
    required this.userId,
    required this.token,
    required this.status,
  });
  
  final String? userId;
  final String? token;
  final AuthStatus status;
  
  // Serialization methods are fine (they're still just data transformations)
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'token': token,
    'status': status.name,
  };
  
  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    userId: json['userId'],
    token: json['token'],
    status: AuthStatus.values.byName(json['status']),
  );
}

// Message: describes what happened, carries data
sealed class AuthMessage {}
final class LoginRequested extends AuthMessage {
  LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
}
final class LoginSucceeded extends AuthMessage {
  LoginSucceeded({required this.userId, required this.token});
  final String userId;
  final String token;
}

// Effect: describes what should happen, carries data
sealed class AuthEffect {}
final class AuthenticateUser extends AuthEffect {
  AuthenticateUser({required this.email, required this.password});
  final String email;
  final String password;
}
```

**❌ Bad — Logic or behavior in data classes:**

```dart
// ❌ BAD: State with methods that contain logic
final class AuthState {
  const AuthState({required this.user});
  final User? user;
  
  // ❌ Business logic in the state class
  bool get canAccessPremiumFeatures => 
    user != null && user!.subscription.isActive && user!.tier == 'premium';
}

// ❌ BAD: Message that does work
final class LoginRequested extends AuthMessage {
  LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  
  // ❌ Validation logic in the message
  bool get isValid => email.contains('@') && password.length >= 8;
}

// ❌ BAD: Effect that knows how to execute itself
final class AuthenticateUser extends AuthEffect {
  // ❌ Effect contains the HTTP client and can execute itself
  Future<AuthResult> execute(HttpClient client) async {
    return await client.post('/auth/login', body: {...});
  }
}
```

**The rule:** If you can't easily serialize it to JSON, it's not "just data". Move the logic to `update` (for business rules) or `EffectHandler` (for execution).

---

## Why pure functions matter

Puer enforces that your `update` function is **pure**. This is not a stylistic preference — it is an architectural constraint that makes your code testable, predictable, and debuggable.

### What "pure" means

A pure function:
- Returns the same output for the same inputs, every time (deterministic)
- Has no side effects — does not mutate external state, make network calls, access databases, read files, generate random numbers, or call `DateTime.now()`
- Is synchronous — returns immediately, no `async`/`await`, no `Future`, no `Stream`

### What you CANNOT do in `update`

```dart
// ❌ BAD: async work
Next<State, Effect> update(State state, Message msg) async { ... }

// ❌ BAD: network call
Next<State, Effect> update(State state, Message msg) {
  final data = await http.get('...');  // Side effect!
  return next(state: state.copyWith(data: data));
}

// ❌ BAD: random numbers
Next<State, Effect> update(State state, Message msg) {
  final id = Random().nextInt(1000);  // Non-deterministic!
  return next(state: state.copyWith(id: id));
}

// ❌ BAD: current time
Next<State, Effect> update(State state, Message msg) {
  final now = DateTime.now();  // Non-deterministic!
  return next(state: state.copyWith(timestamp: now));
}

// ❌ BAD: mutating external state
Next<State, Effect> update(State state, Message msg) {
  globalCache.clear();  // Side effect!
  return next(state: state.copyWith(cleared: true));
}
```

### What you SHOULD do instead

**Return effects as data. Let effect handlers do the dirty work.**

```dart
// ✅ GOOD: return an effect, handler will do the HTTP call
sealed class Effect {}
final class FetchData extends Effect {
  const FetchData(this.url);
  final String url;
}

Next<State, Effect> update(State state, Message msg) {
  return switch (msg) {
    LoadRequested() => next(
      state: state.copyWith(isLoading: true),
      effects: [FetchData('https://api.example.com/data')],
    ),
    // ...
  };
}

// Effect handler does the async work:
final class FetchDataHandler implements EffectHandler<Effect, Message> {
  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    switch (effect) {
      case FetchData(:final url):
        final data = await http.get(url);  // Async work happens here
        emit(DataLoaded(data));
    }
  }
}
```

### Why this matters

1. **Testing:** You can test every state transition with a single synchronous function call. No mocks, no async gaps, no flakiness.
2. **Time travel:** Because `update` is pure, you can replay any sequence of messages and always get the same state. This is how `TimeTravelFeature` works.
3. **Reasoning:** Looking at `update` tells you *exactly* what happens for every message. No hidden behavior.

---

## Effect handler philosophy

Effect handlers are **execution adapters**, not business logic. They should be "stupid" — their only job is to translate an `Effect` data value into a real-world side effect and report the outcome as a message.

### Good handler: thin, no decisions

```dart
final class SendEmailHandler implements EffectHandler<Effect, Message> {
  const SendEmailHandler(this._emailService);
  final EmailService _emailService;

  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    switch (effect) {
      case SendEmail(:final to, :final subject, :final body):
        try {
          await _emailService.send(to: to, subject: subject, body: body);
          emit(EmailSent());
        } on EmailException catch (e) {
          emit(EmailFailed(e.message));
        }
    }
  }
}
```

**This handler is good because:**
- It has no conditionals based on business rules (no `if (user.isPremium) ...`)
- It translates the `SendEmail` effect into a service call, reports success/failure
- All decisions are made in `update`, not here

### Bad handler: fat, contains business logic

```dart
// ❌ BAD: business logic in the handler
final class SendEmailHandler implements EffectHandler<Effect, Message> {
  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    switch (effect) {
      case SendEmail(:final to, :final subject, :final body, :final user):
        // ❌ Business rule: should be in update, not here!
        if (!user.isPremium && body.length > 500) {
          emit(EmailFailed('Premium required for long emails'));
          return;
        }
        
        // ❌ Another business rule: retries based on user tier
        final maxRetries = user.isPremium ? 5 : 1;
        for (int i = 0; i < maxRetries; i++) {
          try {
            await _emailService.send(to: to, subject: subject, body: body);
            emit(EmailSent());
            return;
          } catch (e) {
            if (i == maxRetries - 1) emit(EmailFailed(e.toString()));
          }
        }
    }
  }
}
```

**Why this is bad:**
- You cannot test the "premium check" without running the handler (async, requires mocks)
- The retry logic is not visible in `update` — hidden behavior
- Time-travel replay will re-run these checks, possibly with inconsistent results

### The correct pattern: logic in update, execution in handler

```dart
// ✅ update decides what to do
Next<State, Effect> update(State state, Message msg) {
  return switch (msg) {
    SendEmailRequested(:final to, :final body): {
      // Business logic: check if allowed
      if (!state.user.isPremium && body.length > 500) {
        return next(state: state.copyWith(error: 'Premium required'));
      }
      
      // Decide retry strategy based on user tier
      final maxRetries = state.user.isPremium ? 5 : 1;
      
      return next(
        state: state.copyWith(isSending: true),
        effects: [SendEmail(to: to, body: body, maxRetries: maxRetries)],
      );
    },
    // ...
  };
}

// ✅ Handler is dumb: just executes the effect as instructed
final class SendEmailHandler implements EffectHandler<Effect, Message> {
  @override
  Future<void> call(Effect effect, MsgEmitter<Message> emit) async {
    switch (effect) {
      case SendEmail(:final to, :final body, :final maxRetries):
        for (int i = 0; i < maxRetries; i++) {
          try {
            await _emailService.send(to: to, body: body);
            emit(EmailSent());
            return;
          } catch (e) {
            if (i == maxRetries - 1) emit(EmailFailed(e.toString()));
          }
        }
    }
  }
}
```

Now the premium check and retry count logic live in `update` (testable, pure), and the handler just follows instructions.

---

### Multiple handlers per feature

A `Feature` accepts a **list** of effect handlers, not just one. You can (and often should) register multiple handlers that each focus on a specific concern.

**Example: feature with multiple handlers**

```dart
final feature = Feature<State, Message, Effect>(
  initialState: initialState,
  update: update,
  effectHandlers: [
    HttpEffectHandler(httpClient),        // Handles HTTP effects
    StorageEffectHandler(storage),        // Handles storage effects
    NavigationEffectHandler(navigator),   // Handles navigation effects
  ],
);
```

**How it works:** When an effect is emitted from `update`, the `Feature` forwards it to **every registered handler**. Each handler inspects the effect and decides whether to process it (typically with a `switch` or type check). Handlers that don't recognize the effect simply ignore it.

**Benefits of multiple handlers:**
- **Separation of concerns**: HTTP logic lives in one place, storage in another, navigation in a third
- **Independent testing**: test each handler in isolation
- **Reusability**: the same `HttpEffectHandler` can be reused across multiple features (see The adapter pattern below to know how)

---

### Composable handler wrappers

The `puer_effect_handlers` package provides **wrapper handlers** that add behavior to existing handlers without modifying them. These wrappers implement the decorator pattern and can be chained via extension methods.

**Available wrappers:**

| Wrapper | Purpose | Use case |
|---|---|---|
| `DebounceEffectHandler` | Delays effect execution, canceling previous invocations if new effects arrive | Debounce search queries, user input |
| `SequentialEffectHandler` | Queues effects and processes them one at a time | Ensure ordered execution for shared resources |
| `IsolateEffectHandler` | Offloads effect execution to a separate isolate | Heavy computation without blocking the UI thread |
| `AdaptEffectHandler` | Maps effect and message types for reusable generic handlers | Adapt a universal `HttpHandler` to feature-specific types |

**Example: debounce + run in another isolate execution**

```dart
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

final feature = Feature<State, Message, Effect>(
  initialState: initialState,
  update: update,
  effectHandlers: [
    MyEffectHandler(service)
      .isolated()
      .debounced(Duration(milliseconds: 300)),
  ],
);
```

Use this package as a base and create your own transformers.

---

### The adapter pattern: reusable generic handlers

One of the most powerful patterns in puer is writing **generic, reusable handlers** that operate on simple, universal types (like `HttpRequest`/`HttpResponse`, `DbQuery`/`DbResult`), and then **adapting** them to feature-specific effect and message types.

**The problem:** Without adapters, every feature needs its own handler, even if the underlying work (HTTP call, database query, etc.) is identical.

**The solution:** Write the handler once for generic types, then use `AdaptEffectHandler` to map your feature's types to the generic types.

**Example: reusable HTTP handler**

```dart
// Step 1: Define generic HTTP types (shared across all features)
sealed class HttpEffect {}
final class HttpGet extends HttpEffect {
  const HttpGet(this.url);
  final String url;
}

sealed class HttpMessage {}
final class HttpSuccess extends HttpMessage {
  const HttpSuccess(this.body);
  final String body;
}
final class HttpFailure extends HttpMessage {
  const HttpFailure(this.error);
  final String error;
}

// Step 2: Write a generic HTTP handler (write once, reuse everywhere)
final class HttpEffectHandler 
    implements EffectHandler<HttpEffect, HttpMessage> {
  const HttpEffectHandler(this._client);
  final HttpClient _client;

  @override
  Future<void> call(HttpEffect effect, MsgEmitter<HttpMessage> emit) async {
    switch (effect) {
      case HttpGet(:final url):
        try {
          final response = await _client.get(url);
          emit(HttpSuccess(response.body));
        } on Exception catch (e) {
          emit(HttpFailure(e.toString()));
        }
    }
  }
}

// Step 3: Adapt it to feature-specific types
sealed class UserEffect {}
final class LoadUser extends UserEffect {
  const LoadUser(this.userId);
  final String userId;
}

sealed class UserMessage {}
final class UserLoaded extends UserMessage {
  const UserLoaded(this.user);
  final User user;
}
final class UserLoadFailed extends UserMessage {
  const UserLoadFailed(this.error);
  final String error;
}

// Adapter: maps UserEffect → HttpEffect and HttpMessage → UserMessage
final userHandler = HttpEffectHandler(httpClient).adapt(
  effectMapper: (UserEffect effect) {
    // Convert UserEffect → HttpEffect
    return switch (effect) {
      LoadUser(:final userId) => HttpGet('https://api.example.com/users/$userId'),
    };
  },
  messageMapper: (HttpMessage message) {
    // Convert HttpMessage → UserMessage
    return switch (message) {
      HttpSuccess(:final body) => UserLoaded(User.fromJson(body)),
      HttpFailure(:final error) => UserLoadFailed(error),
    };
  },
);

// Use the adapted handler in your feature
final feature = Feature<UserState, UserMessage, UserEffect>(
  initialState: initialState,
  update: userUpdate,
  effectHandlers: [userHandler],
);
```

**Why this pattern is powerful:**
- **Write once, reuse everywhere**: one `HttpEffectHandler`, adapted to every feature that needs HTTP
- **Testability**: test the generic handler once, then test only the mapping functions for each feature
- **Separation of concerns**: HTTP logic is completely separate from domain logic (user loading, product fetching, etc.)
- **True Elm Architecture style**: effects are pure data, execution is generic and reusable

**Use cases:**
- HTTP handlers (GET, POST, etc.) adapted to domain-specific effects
- Database query handlers adapted to feature-specific query effects
- Random number generators adapted to features that need randomness
- File I/O handlers adapted to save/load specific domain objects

This is one of the most underrated patterns in TEA-style architectures, and `puer_effect_handlers` makes it trivial to implement.

---

## Traceability: Why explicit messages matter

One of puer's biggest advantages over simpler patterns is **traceability**. Every state change is caused by a message, and both are recorded in the `transitions` stream.

How does it looks in real world?

### Level 1: Direct mutation

Consider a simple state manager where you call methods directly (like a Cubit):

When your app logs state changes, you see:

```
Transaction {
  before: AuthState.authenticated,
  after: AuthState.unauthenticated
}
```

**You know WHAT changed, but not WHY.** Was it a manual logout? A token expiration? You can't tell from the log.

### Level 2: Event-based state management

In event-based patterns (like BLoC), every state change is triggered by an event:

Now your logs show:

```
Transaction {
  before: AuthState.authenticated,
  event: LogoutRequested,
  after: AuthState.unauthenticated
}
```

**You know WHY the state changed**, but side effects (network calls, storage operations) are hidden inside event handlers. If logout fails, you can't see which effects were triggered from the log alone.

### Level 3: The puer approach

In puer, every state change is caused by a message, **and effects are explicit data**:

When you request logout, your logs from `feature.transitions` show:

```
Transaction {
  before: AuthState.authenticated,
  message: LogoutRequested,
  after: AuthState.loggingOut,
  effects: [PerformLogout]
}

Transaction {
  before: AuthState.loggingOut,
  message: LogoutSucceeded,
  after: AuthState.unauthenticated,
  effects: [CleanData]
}
```

**You know exactly WHY each state changed AND what side effects were triggered.** The complete flow is visible:
1. User requests logout → state becomes "logging out" → logout effect is triggered
2. Logout completes successfully → state becomes "unauthenticated" → also send effect to clean data

If a bug report says "logout didn't work", you can check the transition log and see:
- Was `PerformLogout` effect emitted?
- Did `LogoutSucceeded` message ever arrive?
- Where in the flow did it fail?

### When traceability matters most

Use explicit messages (puer) over direct mutation or event-based patterns when:

- **Critical state transitions** need audit trails (auth, payments, user data)
- **Debugging production issues** requires understanding why state changed
- **Complex flows** have multiple paths to the same state (logged out via timeout vs manual logout)
- **Time-travel debugging** is valuable for your feature
- **Effect execution** needs to be visible in logs (not hidden inside handlers)
- **Analytics** is perfectly handled by traceability. Just listen for exact transaction and send events.

For simple, local UI state (e.g., "is this menu open?"), direct mutation is fine. For business-critical state, full traceability is worth the cost of defining message types.

---

## Quick start

This quick start builds a counter feature in three steps, progressively introducing core puer concepts:

1. **Step 1:** Pure state — a counter with increment/decrement, no side effects
2. **Step 2:** Add persistence — save the count on every update
3. **Step 3:** Load on init — restore the saved count when the feature starts

**Add dependencies first:**

```yaml
# pubspec.yaml
dependencies:
  puer: ^1.0.0-alpha.1
  puer_flutter: ^1.0.0-alpha.1   # Flutter apps only

dev_dependencies:
  puer_test: ^1.0.0-alpha.1      # For testing
```

---

### Step 1: Pure state (no side effects)

Start with the simplest possible feature: an integer counter with increment and decrement.

**Domain types:**

```dart
import 'package:puer/puer.dart';

// State: just an integer count
final class CounterState {
  const CounterState({required this.count});
  final int count;
}

// Messages: sealed class for exhaustive switch handling
sealed class CounterMessage {}
final class Increment extends CounterMessage {}
final class Decrement extends CounterMessage {}
```

**Update function:**

```dart
// Effect type = Never (no side effects yet)
Next<CounterState, Never> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      Increment() => next(state: CounterState(count: state.count + 1)),
      Decrement() => next(state: CounterState(count: state.count - 1)),
    };
```

**Create the feature:**

```dart
final feature = Feature<CounterState, CounterMessage, Never>(
  initialState: const CounterState(count: 0),
  update: counterUpdate,
);

feature.init();
feature.accept(Increment());
print(feature.state.count);  // 1
```

**Key takeaway:** The `update` function is pure — given the same state and message, it always returns the same new state. No async, no side effects, easy to test.

---

### Step 2: Add persistence (save on every update)

Now we want to save the count to persistent storage every time it changes. In puer, `update` never does async work — instead, it returns an `Effect` value that describes what should happen. An `EffectHandler` executes the effect.

**What changes:**

1. Add an `Effect` type to represent "save this value"
2. Update the `update` function to return a `SaveCount` effect on every state change
3. Write an `EffectHandler` that performs the actual save operation
4. Register the handler with the feature

**Add the effect type:**

```dart
// New: effect sealed class
sealed class CounterEffect {}
final class SaveCount extends CounterEffect {
  const SaveCount(this.count);
  final int count;
}
```

**Update the `update` function signature and logic:**

```dart
// Change Never → CounterEffect
Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage message,
) =>
    switch (message) {
      Increment() => next(
          state: CounterState(count: state.count + 1),
          effects: [SaveCount(state.count + 1)],  // Emit save effect
        ),
      Decrement() => next(
          state: CounterState(count: state.count - 1),
          effects: [SaveCount(state.count - 1)],  // Emit save effect
        ),
    };
```

**Write the effect handler:**

```dart
// Abstract storage interface (implementation not shown)
abstract interface class CounterStorage {
  Future<void> saveCount(int count);
}

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
        // This is a fire-and-forget effect — no message emitted back
    }
  }
}
```

**Register the handler:**

```dart
final storage = ...; // Your storage implementation

final feature = Feature<CounterState, CounterMessage, CounterEffect>(
  initialState: const CounterState(count: 0),
  update: counterUpdate,
  effectHandlers: [SaveCountHandler(storage)],  // Register handler
);

feature.init();
feature.accept(Increment());
// update runs (synchronous), state changes, SaveCount effect is emitted
// SaveCountHandler receives SaveCount, performs async save
```

**Key takeaway:** `update` stays pure and testable. Effects are plain data values. Handlers do the dirty async work and are tested separately.

---

### Step 3: Load on init (restore saved count)

Now we want to load the saved count when the feature starts. Puer provides `initialEffects` for exactly this: effects that are triggered immediately when `feature.init()` is called.

**What changes:**

1. Add a `LoadCount` effect
2. Add a `CountLoaded` message (the handler will emit this when load completes)
3. Handle `CountLoaded` in `update` to update the state
4. Add a `LoadCount` handler
5. Pass `[LoadCount()]` to the `initialEffects` parameter

**Add the new effect and message:**

```dart
// Add to effect sealed class:
sealed class CounterEffect {}
final class SaveCount extends CounterEffect {
  const SaveCount(this.count);
  final int count;
}
final class LoadCount extends CounterEffect {}  // New

// Add to message sealed class:
sealed class CounterMessage {}
final class Increment extends CounterMessage {}
final class Decrement extends CounterMessage {}
final class CountLoaded extends CounterMessage {  // New
  const CountLoaded(this.count);
  final int count;
}
```

**Handle `CountLoaded` in `update`:**

```dart
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
      CountLoaded(:final count) => next(  // New case
          state: CounterState(count: count),
        ),
    };
```

**Extend the storage interface and handler:**

```dart
abstract interface class CounterStorage {
  Future<void> saveCount(int count);
  Future<int?> loadCount();  // New
}

final class CounterEffectHandler
    implements EffectHandler<CounterEffect, CounterMessage> {
  const CounterEffectHandler(this._storage);
  final CounterStorage _storage;

  @override
  Future<void> call(
    CounterEffect effect,
    MsgEmitter<CounterMessage> emit,
  ) async {
    switch (effect) {
      case SaveCount(:final count):
        await _storage.saveCount(count);
      case LoadCount():  // New case
        final count = await _storage.loadCount();
        if (count != null) {
          emit(CountLoaded(count));  // Send message back to feature
        }
    }
  }
}
```

**Create the feature with `initialEffects`:**

```dart
final feature = Feature<CounterState, CounterMessage, CounterEffect>(
  initialState: const CounterState(count: 0),
  update: counterUpdate,
  effectHandlers: [CounterEffectHandler(storage)],
  initialEffects: [LoadCount()],  // Run immediately on init()
);

feature.init();
// init() triggers LoadCount effect → handler loads count → emits CountLoaded(42)
// → update receives CountLoaded(42) → state becomes CounterState(count: 42)
```

**Key takeaway:** `initialEffects` lets you run async setup logic (load saved state, fetch config, etc.) when the feature starts, while keeping `update` pure. The flow is: `init()` → effect emitted → handler runs async work → handler emits message → `update` receives message → state updates.

---

### Understanding `next()`

The `next()` helper constructs the return value for `update`. It accepts optional `state` and `effects` parameters:

```dart
// No state change, no effects:
return next();  // equivalent to (null, const [])

// Update state, no effects:
return next(state: newState);  // equivalent to (newState, const [])

// Update state + emit effects:
return next(state: newState, effects: [effect1, effect2]);
```

Returning `state: null` means "do not emit a new state" — the `stateStream` will not fire and widgets will not rebuild.

---

### Integrate with Flutter

To use the feature in Flutter, wrap it in a `FeatureProvider` and consume the state with `FeatureBuilder`:

```dart
import 'package:flutter/material.dart';
import 'package:puer_flutter/puer_flutter.dart';

// Define a typedef to reduce verbosity
typedef CounterFeature = Feature<CounterState, CounterMessage, CounterEffect>;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureProvider<CounterFeature>.create(
        create: (_) => Feature<CounterState, CounterMessage, CounterEffect>(
          initialState: const CounterState(count: 0),
          update: counterUpdate,
          effectHandlers: [CounterEffectHandler(storage)],
          initialEffects: [LoadCount()],
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

    return FeatureBuilder<CounterFeature, CounterState>(
      builder: (context, state) {
        return Scaffold(
          body: Center(child: Text('${state.count}')),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () => feature.accept(Increment()),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                onPressed: () => feature.accept(Decrement()),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**Lifecycle:**
- `FeatureProvider.create` automatically calls `feature.init()` when the widget enters the tree and `feature.dispose()` when it leaves.
- If you create a feature manually outside Flutter (or in tests), you must call `init()` and `dispose()` yourself.

---

### Important notes

**⚠️ State equality**

By default, Dart compares objects by identity (reference), not value. `Feature` only emits a new state if `newState != currentState`. For single-field classes like `CounterState`, this works because you create a new instance on every change. For complex state objects with multiple fields, you should:

1. Override `==` and `hashCode` manually, or
2. Use the `equatable` package: `class MyState extends Equatable`, or
3. Use `freezed` code generation

Without value equality, widgets may rebuild unnecessarily (if you emit a new instance with the same values) or fail to rebuild (if you mutate an existing instance).

**⚠️ Resource management**

Always call `dispose()` when done with a manually-created feature. Feature holds internal stream controllers that must be closed. Safe to call `dispose()` multiple times (idempotent). In Flutter, `FeatureProvider.create()` handles `init()` and `dispose()` automatically.

---

## Testing your features

Puer makes testing trivial. The `puer_test` package provides extension methods for concise, assertion-style tests.

### Testing the `update` function

```dart
import 'package:puer_test/puer_test.dart';
import 'package:test/test.dart';

void main() {
  group('CounterUpdate', () {
    test('Increment increases count by 1', () {
      counterUpdate.test(
        state: const CounterState(count: 5),
        message: Increment(),
        expectedState: const CounterState(count: 6),
      );
    });

    test('Decrement decreases count by 1', () {
      counterUpdate.test(
        state: const CounterState(count: 10),
        message: Decrement(),
        expectedState: const CounterState(count: 9),
      );
    });

    test('Reset returns to zero', () {
      counterUpdate.test(
        state: const CounterState(count: 42),
        message: Reset(),
        expectedState: const CounterState(count: 0),
      );
    });
  });

  group('TodoUpdate', () {
    test('LoadTodos sets isLoading and emits FetchTodos effect', () {
      todoUpdate.test(
        state: const TodoState(todos: [], isLoading: false),
        message: LoadTodos(),
        expectedState: const TodoState(todos: [], isLoading: true),
        expectedEffects: [FetchTodos()],
      );
    });

    test('TodosLoaded updates todos and clears loading flag', () {
      todoUpdate.test(
        state: const TodoState(todos: [], isLoading: true),
        message: TodosLoaded(['Buy milk', 'Walk dog']),
        expectedState: const TodoState(
          todos: ['Buy milk', 'Walk dog'],
          isLoading: false,
        ),
      );
    });
  });
}
```

**No mocks, no async, no setup.** Just call `.test()` on the update function.

### Testing effect handlers

Effect handlers require mocks for their dependencies (repositories, services). This example uses the `mocktail` package.

**Setup:** Add to `dev_dependencies`:
```yaml
dev_dependencies:
  mocktail: ^1.0.0
```

Create a mock class:
```dart
import 'package:mocktail/mocktail.dart';

class MockTodoRepository extends Mock implements TodoRepository {}
```

**Test example:**

```dart
void main() {
  group('FetchTodosHandler', () {
    test('emits TodosLoaded on successful fetch', () async {
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

    test('emits TodosLoadFailed on exception', () async {
      // Note: This example handler doesn't include the error message in the
      // failure message. A production handler might emit TodosLoadFailed(error).
      final mockRepo = MockTodoRepository();
      when(() => mockRepo.fetchAll()).thenThrow(Exception('Network error'));

      final handler = FetchTodosHandler(mockRepo);

      await handler.test(
        effect: FetchTodos(),
        expectedMessages: [TodosLoadFailed()],
      );
    });
  });
}
```

Effect handlers require mocks for their dependencies (repositories, services), but the handler itself is tested in isolation from `update`.

![Test pyramid](media/images/test-pyramid.png)

---

## Resources and next steps

**Learn the foundations**

- [The Elm Architecture guide](https://guide.elm-lang.org/architecture/) — the mental model puer is based on.
- [Dart 3 sealed classes and pattern matching](https://dart.dev/language/patterns) — the idiomatic Dart way to write exhaustive message handling.

**Package documentation**

- [`packages/puer`](./packages/puer/) — core concepts, `Feature` API, `update` contract.
- [`packages/puer_flutter`](./packages/puer_flutter/) — all Flutter widgets with usage examples.
- [`packages/puer_test`](./packages/puer_test/) — how to write concise update and handler tests.
- [`packages/puer_time_travel`](./packages/puer_time_travel/) — enabling and using time-travel debugging.

**Suggested learning path**

1. **Start with the counter example** in this README. Create the `Feature`, write the `update` function, call `accept`, and observe state changes. No Flutter needed yet.
2. **Write tests.** Use `puer_test` to verify your `update` function with `.test()`. Add a few test cases for different messages.
3. **Add effects.** Introduce a sealed `Effect` type and write your first `EffectHandler`. Test it independently with `handler.test()`.
4. **Integrate with Flutter.** Wrap your feature in `FeatureProvider.create` and replace manual stream subscriptions with `FeatureBuilder` and `FeatureListener`.
5. **Enable time travel.** Swap `Feature(...)` for `TimeTravelFeature(name: 'counter', ...)` and open the DevTools extension to inspect the message timeline.
6. **Compose effect handlers.** Explore `puer_effect_handlers` to add debouncing, sequencing, or isolate execution to an existing handler with a single extension method call.
