## 1.0.0

**BREAKING CHANGES:**

- **Renamed all effect handler decorators to "Transformer" pattern** (RxDart-style):
  - `DebounceEffectHandler` → `DebounceTransformer`
  - `SequentialEffectHandler` → `SequentialTransformer`
  - `IsolateEffectHandler` → `IsolateTransformer`
  - `MapEffectHandler` → `MapTransformer`
  - Extension names updated: `DebounceEffectHandlerExt` → `DebounceTransformerExt`, etc.
  
- **Reorganized package structure:**
  - Transformers moved to `src/transformers/` directory
  - Handlers moved to `src/handlers/` directory
  - Updated all exports in `puer_effect_handlers.dart`

**Migration Guide:**

If using extension methods (recommended), **no changes needed**:
```dart
// This code continues to work unchanged
final handler = myHandler.debounced(duration).sequential();
```

If using constructors directly, update class names:
```dart
// Before:
final handler = DebounceEffectHandler(handler: base, duration: dur);

// After:
final handler = DebounceTransformer(handler: base, duration: dur);
```

**Rationale:** Aligns with Dart/RxDart conventions where transformers modify behavior of underlying handlers, similar to how `StreamTransformer` works with streams. This makes the decorator pattern more obvious and familiar to Dart developers.

**Other changes:**

- Add StreamEffectHandler (#46)
- Make `effectMapper` and `messageMapper` optional in `MapTransformer` and
  `MapTransformerExt.map()` (#65). When omitted, a direct runtime type cast
  is used as a fallback. Effects or messages that cannot be cast are silently
  dropped.
- Mapper functions may now return `null` to explicitly drop an effect or
  message (`Transform<From, To?>` signature).

## 1.0.0-alpha.1

- Initial release
