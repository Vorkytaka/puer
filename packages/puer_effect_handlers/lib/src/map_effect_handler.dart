import 'dart:async';

import 'package:puer/puer.dart';

/// A function type that converts a value of type [From] to a value of type [To].
///
/// Used by [MapEffectHandler] to map effects and messages between inner and outer types.
typedef Transform<From, To> = To Function(From from);

/// An [EffectHandler] implementation that maps an inner handler to a different
/// effect and message type pair.
///
/// This is a key component in achieving true **The Elm Architecture** style:
/// it allows you to write **generic, reusable effect handlers** that operate on
/// simple, universal types (like `HttpRequest`/`HttpResponse`, `DbQuery`/`DbResult`),
/// and then map them to your feature-specific effect and message types.
///
/// Instead of writing a custom handler for every feature, you can:
/// 1. Create a generic handler once (e.g., `HttpEffectHandler` that handles HTTP requests).
/// 2. Map it to each feature's domain types using [MapEffectHandler].
///
/// [MapEffectHandler] wraps the inner handler and performs two mappings:
/// - **Effect mapping**: converts [OuterEffect] → [InnerEffect] before delegating.
/// - **Message mapping**: converts [InnerMessage] → [OuterMessage] before emitting.
///
/// Both mappings are pure functions and are applied synchronously on every call.
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
/// See also:
/// - [MapEffectHandlerExt] for the fluent `.map(...)` extension method.
final class MapEffectHandler<InnerEffect, InnerMessage, OuterEffect,
    OuterMessage> implements EffectHandler<OuterEffect, OuterMessage> {
  /// The underlying effect handler that processes effects of type [InnerEffect]
  /// and emits messages of type [InnerMessage].
  final EffectHandler<InnerEffect, InnerMessage> _effectHandler;

  /// Converts an [OuterEffect] to an [InnerEffect] before delegating to [_effectHandler].
  final Transform<OuterEffect, InnerEffect?> _effectMapper;

  /// Converts an [InnerMessage] emitted by [_effectHandler] to an [OuterMessage].
  final Transform<InnerMessage, OuterMessage?> _messageMapper;

  /// Creates a new [MapEffectHandler].
  ///
  /// - [effectHandler]: The inner handler that processes [InnerEffect] values.
  /// - [effectMapper]: Maps [OuterEffect] → [InnerEffect] before each delegation.
  /// - [messageMapper]: Maps [InnerMessage] → [OuterMessage] for every emitted message.
  MapEffectHandler({
    required EffectHandler<InnerEffect, InnerMessage> effectHandler,
    required Transform<OuterEffect, InnerEffect?> effectMapper,
    required Transform<InnerMessage, OuterMessage?> messageMapper,
  })  : _effectHandler = effectHandler,
        _effectMapper = effectMapper,
        _messageMapper = messageMapper;

  /// Handles the given [effect] by mapping it to the inner type and delegating
  /// to the wrapped handler.
  ///
  /// Every message emitted by the inner handler is mapped to [OuterMessage]
  /// and forwarded to [emit].
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
  ) async {
    final innerEffect = _effectMapper(effect);

    if (innerEffect == null) {
      return;
    }

    void innerEmit(InnerMessage message) {
      final outerMessage = _messageMapper(message);
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
/// [MapEffectHandler] directly. This is essential for writing reusable,
/// generic effect handlers in true **The Elm Architecture** style.
///
/// Example with a generic HTTP handler:
/// ```dart
/// final httpHandler = HttpEffectHandler();
///
/// // Map to feature-specific types
/// final mapped = httpHandler.map(
///   effectMapper: (MyEffect effect) => effect.toHttpRequest(),
///   messageMapper: (HttpResponse response) => MyMessage.fromHttp(response),
/// );
/// ```
extension MapEffectHandlerExt<InnerEffect, InnerMessage>
    on EffectHandler<InnerEffect, InnerMessage> {
  /// Wraps this handler with type-mapping transformers for effects and messages.
  ///
  /// Returns a new [MapEffectHandler] that maps [OuterEffect] → [InnerEffect]
  /// before delegating and [InnerMessage] → [OuterMessage] before emitting.
  ///
  /// - [effectMapper]: Converts an incoming [OuterEffect] to [InnerEffect].
  /// - [messageMapper]: Converts an emitted [InnerMessage] to [OuterMessage].
  EffectHandler<OuterEffect, OuterMessage> map<OuterEffect, OuterMessage>({
    required Transform<OuterEffect, InnerEffect?> effectMapper,
    required Transform<InnerMessage, OuterMessage?> messageMapper,
  }) {
    return MapEffectHandler(
      effectHandler: this,
      effectMapper: effectMapper,
      messageMapper: messageMapper,
    );
  }
}
