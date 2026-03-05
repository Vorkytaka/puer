# Puer Effect Handlers

<p align="center">
<img src="https://raw.githubusercontent.com/Vorkytaka/puer/master/media/images/logo.png" height="200" alt="Puer" />
</p>

<p align="center">
<a href="https://pub.dev/packages/puer_effect_handlers"><img src="https://img.shields.io/pub/v/puer_effect_handlers.svg" alt="Pub"></a>
<a href="https://github.com/Vorkytaka/puer/actions"><img src="https://github.com/Vorkytaka/puer/actions/workflows/validate_repository.yml/badge.svg" alt="CI"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Composable effect handler wrappers for **[puer](https://pub.dev/packages/puer)** — a reactive, functional state management library based on The Elm Architecture.

This package provides ready-to-use wrappers that add behavior to your effect handlers without modifying them. Chain them together via extension methods to create sophisticated effect-execution policies.

---

## Features

✅ **Debounce** — Delay effect execution, canceling previous invocations if new effects arrive  
✅ **Sequential** — Queue effects and process them one at a time, ensuring strict ordering  
✅ **Isolate** — Offload heavy computation to a separate isolate without blocking the UI thread  
✅ **Adapt** — Map effect and message types to enable truly reusable generic handlers  
✅ **Composable** — Chain wrappers via extension methods (`.debounced().isolated()`)  
✅ **Zero modification** — Wrap existing handlers without changing their code

---

## Installation

Add `puer_effect_handlers` to your `pubspec.yaml`:

```yaml
dependencies:
  puer: ^1.0.0-alpha.1
  puer_effect_handlers: ^1.0.0-alpha.1
```

---

## Quick Example

```dart
import 'package:puer/puer.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

// Your effect handler
final myHandler = SearchEffectHandler(searchService);

// Wrap it with debounce and isolate execution
final feature = Feature<State, Message, Effect>(
  initialState: initialState,
  update: update,
  effectHandlers: [
    myHandler
      .debounced(Duration(milliseconds: 300))  // Debounce for 300ms
      .isolated(),                              // Run in separate isolate
  ],
);
```

---

## Core Concept: Composable Wrappers

The handlers in this package implement the **decorator pattern**. Instead of creating custom handlers with complex execution logic, you write simple handlers and wrap them with behavior modifiers.

Every wrapper is an `EffectHandler` itself, so wrappers compose naturally via extension methods:

```dart
myHandler
  .debounced(Duration(milliseconds: 500))  // Add debouncing
  .sequential()                            // Ensure sequential execution
  .isolated()                              // Run in isolate
```

---

## Available Wrappers

### 1. DebounceEffectHandler

**Purpose:** Delays effect execution. If new effects arrive before the delay elapses, previous effects are canceled and only the latest effect is processed.

**When to use:**
- Debounce search queries as the user types
- Delay API calls triggered by rapid UI interactions
- Throttle save operations triggered by frequent updates

#### Usage

```dart
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

// Using the extension method (recommended)
final debouncedHandler = myHandler.debounced(
  Duration(milliseconds: 300),
);

// Or using the constructor
final debouncedHandler = DebounceEffectHandler(
  duration: Duration(milliseconds: 300),
  handler: myHandler,
);
```

#### Example: Search as you type

```dart
sealed class SearchEffect {}
final class PerformSearch extends SearchEffect {
  const PerformSearch(this.query);
  final String query;
}

final class SearchHandler implements EffectHandler<SearchEffect, SearchMessage> {
  const SearchHandler(this._searchService);
  final SearchService _searchService;

  @override
  Future<void> call(SearchEffect effect, MsgEmitter<SearchMessage> emit) async {
    switch (effect) {
      case PerformSearch(:final query):
        try {
          final results = await _searchService.search(query);
          emit(SearchSucceeded(results));
        } on Exception catch (e) {
          emit(SearchFailed(e.toString()));
        }
    }
  }
}

// Wrap the handler to debounce search requests
final feature = Feature<SearchState, SearchMessage, SearchEffect>(
  initialState: initialState,
  update: searchUpdate,
  effectHandlers: [
    SearchHandler(searchService).debounced(Duration(milliseconds: 300)),
  ],
);
```

**Result:** When the user types "flutter", the handler receives effects in rapid succession:

```
PerformSearch("f")       ← canceled
PerformSearch("fl")      ← canceled
PerformSearch("flu")     ← canceled
PerformSearch("flutt")   ← canceled
PerformSearch("flutter") ← executed after 300ms
```

Only the final search query is executed, saving unnecessary API calls.

---

### 2. SequentialEffectHandler

**Purpose:** Queues effects and processes them one at a time in the order they arrive. Guarantees that no two effects are handled simultaneously.

**When to use:**
- Effects that modify shared resources (file system, database)
- Operations that must maintain strict ordering (transaction sequences)
- Prevent race conditions when effects depend on previous results

#### Usage

```dart
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

// Using the extension method (recommended)
final sequentialHandler = myHandler.sequential();

// Or using the constructor
final sequentialHandler = SequentialEffectHandler(
  handler: myHandler,
);
```

#### Example: Sequential file operations

```dart
sealed class FileEffect {}
final class SaveFile extends FileEffect {
  const SaveFile(this.path, this.content);
  final String path;
  final String content;
}

final class FileHandler implements EffectHandler<FileEffect, FileMessage> {
  const FileHandler(this._fileService);
  final FileService _fileService;

  @override
  Future<void> call(FileEffect effect, MsgEmitter<FileMessage> emit) async {
    switch (effect) {
      case SaveFile(:final path, :final content):
        await _fileService.write(path, content);
        emit(FileSaved(path));
    }
  }
}

// Wrap the handler to ensure sequential execution
final feature = Feature<EditorState, EditorMessage, FileEffect>(
  initialState: initialState,
  update: editorUpdate,
  effectHandlers: [
    FileHandler(fileService).sequential(),
  ],
);
```

**Result:** If the user triggers multiple save operations rapidly, they execute one at a time:

```
SaveFile("doc.txt", "Hello")     ← starts immediately
SaveFile("doc.txt", "Hello World") ← queued, waits for first to complete
SaveFile("doc.txt", "Hello World!") ← queued, waits for second to complete
```

Each save completes before the next one starts, preventing file corruption.

---

### 3. IsolateEffectHandler

**Purpose:** Offloads effect execution to a separate isolate, allowing heavy computation to run without blocking the UI thread.

**When to use:**
- Computationally expensive tasks (image processing, parsing, encryption)
- Large data transformations (JSON parsing, CSV processing)
- Any synchronous blocking operation that would freeze the UI

#### Usage

```dart
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

// Using the extension method (recommended)
final isolatedHandler = myHandler.isolated();

// Or using the constructor
final isolatedHandler = IsolateEffectHandler(
  effectHandler: myHandler,
);
```

#### Example: Heavy image processing

```dart
sealed class ImageEffect {}
final class ProcessImage extends ImageEffect {
  const ProcessImage(this.imageData);
  final List<int> imageData;
}

final class ImageHandler implements EffectHandler<ImageEffect, ImageMessage> {
  const ImageHandler();

  @override
  Future<void> call(ImageEffect effect, MsgEmitter<ImageMessage> emit) async {
    switch (effect) {
      case ProcessImage(:final imageData):
        // Heavy synchronous operation
        final processed = applyFilters(imageData);
        emit(ImageProcessed(processed));
    }
  }
}

// Wrap the handler to run in a separate isolate
final feature = Feature<ImageState, ImageMessage, ImageEffect>(
  initialState: initialState,
  update: imageUpdate,
  effectHandlers: [
    ImageHandler().isolated(),
  ],
);
```

**Result:** The heavy `applyFilters()` computation runs in a separate isolate. The UI remains responsive while processing happens in the background.

#### Important Notes

**⚠️ Isolate Constraints:**
- Only types that can be sent through `SendPort` are supported (primitives, lists, maps, etc.)
- Custom classes must be serializable or implement proper `SendPort` transfer
- Closures and functions cannot be sent across isolates
- Each effect spawns a new isolate that is terminated after completion

**Not supported:**
```dart
// ❌ BAD: Custom class without serialization support
final class User {
  const User(this.name);
  final String name;
}
final effect = ProcessUser(User('Alice')); // May fail to transfer
```

**Supported:**
```dart
// ✅ GOOD: Primitive types and serializable data
final effect = ProcessData({
  'name': 'Alice',
  'age': 30,
  'tags': ['developer', 'flutter'],
});
```

---

### 4. AdaptEffectHandler

**Purpose:** Maps effect and message types to enable truly reusable generic handlers. This is the **key to writing handlers once and using them everywhere**.

**When to use:**
- You have a generic handler (HTTP, database, random numbers) that operates on universal types
- You want to adapt it to feature-specific effect and message types
- You need to compose features by adapting child feature handlers to parent types

**Why this matters:** Without adapters, every feature needs its own handler, even if the underlying work is identical. With adapters, you write the handler once for generic types and map feature-specific types to it.

#### Usage

```dart
import 'package:puer_effect_handlers/puer_effect_handlers.dart';

// Using the extension method (recommended)
final adaptedHandler = genericHandler.adapt(
  effectMapper: (MyEffect effect) => effect.toGenericEffect(),
  messageMapper: (GenericMessage message) => message.toMyMessage(),
);

// Or using the constructor
final adaptedHandler = AdaptEffectHandler(
  effectHandler: genericHandler,
  effectMapper: (MyEffect effect) => effect.toGenericEffect(),
  messageMapper: (GenericMessage message) => message.toMyMessage(),
);
```

#### Example: Reusable HTTP handler

**Step 1: Define generic HTTP types (write once, shared across all features)**

```dart
// Generic HTTP effect and message types
sealed class HttpEffect {}
final class HttpGet extends HttpEffect {
  const HttpGet(this.url);
  final String url;
}
final class HttpPost extends HttpEffect {
  const HttpPost(this.url, this.body);
  final String url;
  final String body;
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
```

**Step 2: Write a generic HTTP handler (write once, reuse everywhere)**

```dart
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
      case HttpPost(:final url, :final body):
        try {
          final response = await _client.post(url, body: body);
          emit(HttpSuccess(response.body));
        } on Exception catch (e) {
          emit(HttpFailure(e.toString()));
        }
    }
  }
}
```

**Step 3: Adapt it to feature-specific types**

```dart
// User feature types
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

// Adapt the generic handler to user feature types
final userHandler = HttpEffectHandler(httpClient).adapt(
  effectMapper: (UserEffect effect) {
    return switch (effect) {
      LoadUser(:final userId) => 
        HttpGet('https://api.example.com/users/$userId'),
    };
  },
  messageMapper: (HttpMessage message) {
    return switch (message) {
      HttpSuccess(:final body) => 
        UserLoaded(User.fromJson(jsonDecode(body))),
      HttpFailure(:final error) => 
        UserLoadFailed(error),
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

**Step 4: Reuse the same handler for a different feature**

```dart
// Product feature types
sealed class ProductEffect {}
final class LoadProducts extends ProductEffect {}

sealed class ProductMessage {}
final class ProductsLoaded extends ProductMessage {
  const ProductsLoaded(this.products);
  final List<Product> products;
}
final class ProductsLoadFailed extends ProductMessage {
  const ProductsLoadFailed(this.error);
  final String error;
}

// Adapt the SAME generic handler to product feature types
final productHandler = HttpEffectHandler(httpClient).adapt(
  effectMapper: (ProductEffect effect) {
    return switch (effect) {
      LoadProducts() => HttpGet('https://api.example.com/products'),
    };
  },
  messageMapper: (HttpMessage message) {
    return switch (message) {
      HttpSuccess(:final body) => 
        ProductsLoaded(parseProducts(body)),
      HttpFailure(:final error) => 
        ProductsLoadFailed(error),
    };
  },
);
```

**Why this pattern is powerful:**
- ✅ Write `HttpEffectHandler` once, adapt to every feature that needs HTTP
- ✅ Test the generic handler once, then test only the mapping functions for each feature
- ✅ Separation of concerns: HTTP logic is completely separate from domain logic
- ✅ True Elm Architecture style: effects are pure data, execution is generic and reusable
- ✅ Business logic cannot leak into handlers (generic handlers have no domain knowledge)

---

## Composing Wrappers

Wrappers are designed to compose naturally. Chain them via extension methods to create sophisticated execution policies:

```dart
myHandler
  .debounced(Duration(milliseconds: 300))  // First: debounce
  .sequential()                            // Then: ensure sequential execution
  .isolated()                              // Finally: run in isolate
```

**Order matters:**
- Debounce → Sequential → Isolate means: debounce first, then queue, then offload to isolate
- Sequential → Debounce means: queue first, then debounce each queued effect (rarely useful)

### Example: Search handler with full composition

```dart
final searchHandler = SearchHandler(searchService)
  .adapt(
    effectMapper: (SearchEffect e) => e.toHttpRequest(),
    messageMapper: (HttpMessage m) => m.toSearchMessage(),
  )
  .debounced(Duration(milliseconds: 300))
  .sequential();

final feature = Feature<SearchState, SearchMessage, SearchEffect>(
  initialState: initialState,
  update: searchUpdate,
  effectHandlers: [searchHandler],
);
```

**What this does:**
1. Adapts generic HTTP handler to search feature types
2. Debounces search requests (only execute if user stops typing for 300ms)
3. Ensures sequential execution (if multiple searches somehow trigger, process them one by one)

---

## Common Patterns

### Pattern 1: Debounced search

```dart
final feature = Feature<SearchState, SearchMessage, SearchEffect>(
  initialState: initialState,
  update: searchUpdate,
  effectHandlers: [
    SearchHandler(searchService).debounced(Duration(milliseconds: 300)),
  ],
);
```

### Pattern 2: Sequential database operations

```dart
final feature = Feature<DbState, DbMessage, DbEffect>(
  initialState: initialState,
  update: dbUpdate,
  effectHandlers: [
    DbHandler(database).sequential(),
  ],
);
```

### Pattern 3: Heavy computation in isolate

```dart
final feature = Feature<ProcessingState, ProcessingMessage, ProcessingEffect>(
  initialState: initialState,
  update: processingUpdate,
  effectHandlers: [
    ProcessingHandler().isolated(),
  ],
);
```

### Pattern 4: Reusable HTTP handler

```dart
// Define once
final httpHandler = HttpEffectHandler(httpClient);

// Adapt to each feature
final userHandler = httpHandler.adapt(/* user mappers */);
final productsHandler = httpHandler.adapt(/* product mappers */);
final ordersHandler = httpHandler.adapt(/* order mappers */);
```

### Pattern 5: Full composition

```dart
final handler = MyHandler(service)
  .adapt(effectMapper: ..., messageMapper: ...)
  .debounced(Duration(milliseconds: 500))
  .sequential()
  .isolated();
```

---

## Best Practices

### 1. Keep handlers thin and generic

Handlers should be "stupid" — no business logic, just execution. Adapt generic handlers to feature types rather than writing feature-specific handlers.

```dart
// ✅ GOOD: Generic handler, adapted to feature types
final handler = HttpEffectHandler(client).adapt(
  effectMapper: (MyEffect e) => e.toHttpRequest(),
  messageMapper: (HttpMessage m) => m.toMyMessage(),
);

// ❌ BAD: Feature-specific handler with business logic
final class MyFeatureHandler implements EffectHandler<MyEffect, MyMessage> {
  @override
  Future<void> call(MyEffect effect, MsgEmitter<MyMessage> emit) async {
    // Handler contains feature-specific logic — not reusable!
  }
}
```

### 2. Order wrappers intentionally

The order of wrappers changes behavior. Think through the execution flow:

```dart
// Debounce → Sequential: debounce first, then queue
myHandler.debounced(...).sequential()

// Sequential → Debounce: queue first, then debounce each (rarely useful)
myHandler.sequential().debounced(...)
```

### 3. Use extension methods for clarity

```dart
// ✅ GOOD: Clear and composable
myHandler.debounced(Duration(milliseconds: 300)).sequential()

// ❌ BAD: Verbose and hard to read
SequentialEffectHandler(
  handler: DebounceEffectHandler(
    duration: Duration(milliseconds: 300),
    handler: myHandler,
  ),
)
```

### 4. Dispose handlers when needed

Some wrappers implement `Disposable` (e.g., `DebounceEffectHandler`, `SequentialEffectHandler`). If you manually create them, call `dispose()` when done:

```dart
final handler = myHandler.debounced(Duration(milliseconds: 300));
// Use the handler...
await handler.dispose(); // Clean up timers and resources
```

When using `Feature`, disposal is handled automatically when the feature is disposed.

### 5. Test wrappers independently

Test the base handler first, then test that wrappers add the expected behavior:

```dart
// Test the base handler
test('SearchHandler returns results', () async {
  final handler = SearchHandler(mockService);
  await handler.test(
    effect: PerformSearch('flutter'),
    expectedMessages: [SearchSucceeded(results)],
  );
});

// Test the debounced wrapper
test('Debounced handler cancels previous effects', () async {
  final handler = SearchHandler(mockService)
    .debounced(Duration(milliseconds: 100));
  
  // Trigger multiple effects rapidly
  handler(PerformSearch('f'), emit);
  handler(PerformSearch('fl'), emit);
  handler(PerformSearch('flu'), emit);
  
  await Future.delayed(Duration(milliseconds: 150));
  
  // Only the last effect should execute
  verify(() => mockService.search('flu')).called(1);
  verifyNever(() => mockService.search('f'));
  verifyNever(() => mockService.search('fl'));
});
```

---

## When NOT to Use These Wrappers

**Debouncing:**
- Don't debounce critical operations (payments, auth) where every invocation matters
- Don't debounce when immediate feedback is essential

**Sequential:**
- Don't force sequential execution when effects are independent (unnecessarily slow)
- Don't use for read-only operations that can safely run in parallel

**Isolate:**
- Don't offload lightweight operations (isolate spawn overhead exceeds benefit)
- Don't use when effects contain non-transferable types (closures, Flutter widgets)

**Adapt:**
- Don't use adapters when the handler is already feature-specific (unnecessary indirection)

---

## Learn More

- **[puer package](https://pub.dev/packages/puer)** — Core library documentation
- **[puer_flutter package](https://pub.dev/packages/puer_flutter)** — Flutter integration widgets
- **[Main repository](https://github.com/Vorkytaka/puer)** — Full architecture guide, patterns, and examples
- **[The Elm Architecture](https://guide.elm-lang.org/architecture/)** — The pattern puer is based on

---

## Contributing

This package provides foundational wrappers. If you create useful custom wrappers, consider contributing them via pull request!

---

## License

[MIT](https://github.com/Vorkytaka/puer/blob/master/LICENSE)
