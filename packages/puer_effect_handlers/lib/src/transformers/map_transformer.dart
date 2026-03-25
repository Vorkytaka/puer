import 'dart:async';

import 'package:puer/puer.dart';

/// A function type that converts a value of type [From] to a value of type [To].
///
/// Used by [MapTransformer] to map effects and messages between inner and
/// outer types.
///
/// When used as a nullable-output transformer
/// (`Transform<From, To?>`), returning `null` signals that the value should be
/// dropped: an effect is not forwarded to the inner handler, and a message is
/// not forwarded to the outer emitter.
typedef Transform<From, To> = To Function(From from);

/// A transformer that maps an inner handler to a different effect and message type pair.
///
/// This transformer wraps an existing [EffectHandler] and modifies the types of effects
/// it accepts and messages it emits. This is a key component in achieving true
/// **The Elm Architecture** style: it allows you to write **generic, reusable effect
/// handlers** that operate on simple, universal types (like `HttpRequest`/`HttpResponse`,
/// `DbQuery`/`DbResult`), and then map them to your feature-specific effect and message types.
///
/// Similar to how RxDart's `map` operator transforms stream values, this transformer
/// transforms the type signature of an effect handler while preserving its behavior.
///
/// Instead of writing a custom handler for every feature, you can:
/// 1. Create a generic handler once (e.g., `HttpEffectHandler` that handles
///    HTTP requests).
/// 2. Map it to each feature's domain types using [MapTransformer].
///
/// [MapTransformer] wraps the inner handler and performs two mappings:
/// - **Effect mapping**: converts [OuterEffect] → [InnerEffect] before
///   delegating.
/// - **Message mapping**: converts [InnerMessage] → [OuterMessage] before
///   emitting.
///
/// Both mappers are optional:
/// - When [effectMapper] is `null`, the handler attempts a direct type cast
///   of [OuterEffect] to [InnerEffect]. If the cast fails, the effect is
///   silently dropped and the inner handler is not called.
/// - When [messageMapper] is `null`, each emitted [InnerMessage] is
///   similarly cast to [OuterMessage]. Messages that fail the cast are
///   silently dropped.
/// - A mapper that explicitly returns `null` has the same drop semantics.
///
/// Both mappings are pure functions and are applied synchronously on every
/// call.
///
/// ### Example: Reusable HTTP handler
/// ```dart
/// // Generic HTTP handler (write once, use everywhere)
/// final httpHandler = HttpEffectHandler();
///
/// // Map it to your feature's types
/// final userHandler = httpHandler.map(
///   effectMapper: (UserEffect effect) => effect.toHttpRequest(),
///   messageMapper: (HttpResponse response) => UserMessage.fromHttp(response),
/// );
///
/// final productsHandler = httpHandler.map(
///   effectMapper: (ProductEffect effect) => effect.toHttpRequest(),
///   messageMapper: (HttpResponse response) => ProductMessage.fromHttp(response),
/// );
/// ```
///
/// ### Example: Feature composition
/// ```dart
/// // Child feature handler
/// final childHandler = MyChildEffectHandler();
///
/// // Map it to parent feature types
/// final mappedHandler = childHandler.map(
///   effectMapper: (ParentEffect outer) => outer.toChildEffect(),
///   messageMapper: (ChildMessage inner) => ParentMessage.fromChild(inner),
/// );
/// ```
///
/// ### Example: Omitting mappers when types are the same
/// ```dart
/// // Inner and outer types are identical — no mappers needed.
/// final handler = innerHandler.map<MyEffect, MyMessage>();
/// ```
///
/// See also:
/// - [MapTransformerExt] for the fluent `.map(...)` extension method.
final class MapTransformer<InnerEffect, InnerMessage, OuterEffect, OuterMessage>
    implements EffectHandler<OuterEffect, OuterMessage> {
  /// The underlying effect handler that processes effects of type [InnerEffect]
  /// and emits messages of type [InnerMessage].
  final EffectHandler<InnerEffect, InnerMessage> _effectHandler;

  /// Converts an [OuterEffect] to an [InnerEffect] before delegating to
  /// [_effectHandler].
  ///
  /// When `null`, [_defaultTransformer] is used instead.
  final Transform<OuterEffect, InnerEffect?>? _effectMapper;

  /// Converts an [InnerMessage] emitted by [_effectHandler] to an
  /// [OuterMessage].
  ///
  /// When `null`, [_defaultTransformer] is used instead.
  final Transform<InnerMessage, OuterMessage?>? _messageMapper;

  /// Creates a new [MapTransformer].
  ///
  /// - [effectHandler]: The inner handler that processes [InnerEffect] values.
  /// - [effectMapper]: Optional. Maps [OuterEffect] → [InnerEffect?] before
  ///   each delegation. When `null`, a direct type cast is attempted; if the
  ///   cast fails, the effect is dropped and the inner handler is not called.
  ///   A mapper that returns `null` has the same drop behaviour.
  /// - [messageMapper]: Optional. Maps [InnerMessage] → [OuterMessage?] for
  ///   every emitted message. When `null`, a direct type cast is attempted;
  ///   messages that fail the cast are silently dropped. A mapper that returns
  ///   `null` has the same drop behaviour.
  MapTransformer({
    required EffectHandler<InnerEffect, InnerMessage> effectHandler,
    Transform<OuterEffect, InnerEffect?>? effectMapper,
    Transform<InnerMessage, OuterMessage?>? messageMapper,
  })  : _effectHandler = effectHandler,
        _effectMapper = effectMapper,
        _messageMapper = messageMapper;

  // Fallback transformer used when no explicit mapper is provided.
  // Attempts a direct runtime type cast of [value] to [Outer].
  // Returns `null` if [value] is not an instance of [Outer], which causes the
  // effect or message to be silently dropped by the caller.
  //
  // NOTE: This relies on Dart's reified generics. It works correctly for
  // concrete type arguments, but may produce unexpected results when [Inner]
  // or [Outer] are abstract or themselves generic types.
  static Outer? _defaultTransformer<Inner, Outer>(Inner value) {
    if (value is Outer) {
      return value;
    }

    return null;
  }

  /// Handles the given [effect] by mapping it to the inner type and delegating
  /// to the wrapped handler.
  ///
  /// If [effectMapper] (or the default cast) returns `null` for [effect], the
  /// inner handler is **not** called and this method returns immediately.
  ///
  /// Every message emitted by the inner handler is mapped to [OuterMessage]
  /// via [messageMapper] (or the default cast). Messages that map to `null`
  /// are silently dropped and not forwarded to [emit].
  ///
  /// The return value preserves the [FutureOr] nature of the inner handler:
  /// if the inner handler is asynchronous, the returned [Future] completes
  /// only after the inner handler finishes.
  ///
  /// - [effect]: The outer effect to process.
  /// - [emit]: A function to emit mapped outer messages.
  @override
  FutureOr<void> call(
    OuterEffect effect,
    MsgEmitter<OuterMessage> emit,
  ) {
    final InnerEffect? innerEffect;
    if (_effectMapper != null) {
      innerEffect = _effectMapper(effect);
    } else {
      innerEffect = _defaultTransformer<OuterEffect, InnerEffect>(effect);
    }

    if (innerEffect == null) {
      return null;
    }

    void innerEmit(InnerMessage message) {
      final OuterMessage? outerMessage;
      if (_messageMapper != null) {
        outerMessage = _messageMapper(message);
      } else {
        outerMessage = _defaultTransformer<InnerMessage, OuterMessage>(message);
      }

      if (outerMessage != null) {
        emit(outerMessage);
      }
    }

    return _effectHandler.call(innerEffect, innerEmit);
  }
}

/// Extension methods for [EffectHandler] to map it to a different type pair.
///
/// Provides a fluent way to wrap an existing handler without constructing
/// [MapTransformer] directly. This is essential for writing reusable,
/// generic effect handlers in true **The Elm Architecture** style.
///
/// ### Example with a generic HTTP handler
/// ```dart
/// final httpHandler = HttpEffectHandler();
///
/// // Map to feature-specific types
/// final mapped = httpHandler.map(
///   effectMapper: (MyEffect effect) => effect.toHttpRequest(),
///   messageMapper: (HttpResponse response) => MyMessage.fromHttp(response),
/// );
/// ```
///
/// ### Example omitting mappers when types are already compatible
/// ```dart
/// // No explicit mappers — default cast is used for both directions.
/// final mapped = innerHandler.map<MyEffect, MyMessage>();
/// ```
extension MapTransformerExt<InnerEffect, InnerMessage>
    on EffectHandler<InnerEffect, InnerMessage> {
  /// Wraps this handler with type-mapping transformers for effects and messages.
  ///
  /// Returns a new [MapTransformer] that maps [OuterEffect] → [InnerEffect]
  /// before delegating and [InnerMessage] → [OuterMessage] before emitting.
  ///
  /// - [effectMapper]: Optional. Converts an incoming [OuterEffect] to
  ///   [InnerEffect?]. When `null`, a direct type cast is attempted; effects
  ///   that fail the cast are silently dropped.
  /// - [messageMapper]: Optional. Converts an emitted [InnerMessage] to
  ///   [OuterMessage?]. When `null`, a direct type cast is attempted; messages
  ///   that fail the cast are silently dropped.
  EffectHandler<OuterEffect, OuterMessage> map<OuterEffect, OuterMessage>({
    Transform<OuterEffect, InnerEffect?>? effectMapper,
    Transform<InnerMessage, OuterMessage?>? messageMapper,
  }) {
    return MapTransformer(
      effectHandler: this,
      effectMapper: effectMapper,
      messageMapper: messageMapper,
    );
  }
}
