import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import '../core/feature.dart';
import 'proxy_feature.dart';

/// A wrapper around a [Feature] that intercepts specific types of effects.
///
/// [FeatureEffectWrapper] allows you to handle a subset of effects (of type [E])
/// with a dedicated [EffectHandler]. This enables fine-grained control over the
/// processing of effects emitted by the wrapped feature.
///
/// ### Key Features:
/// - Listens for effects of type [E] and processes them using the provided [handler].
/// - Handles effects from the [initialEffects], the [disposableEffects] and the [effects] stream.
/// - Cleans up resources during disposal, including canceling subscriptions and disposing
///   the [handler] if it implements [Disposable].
///
/// ### Example:
/// ```dart
/// final loggingWrapper = myFeature.wrap<LogEffect>(
///   (effect, emit) => print('Log: $effect'),
/// );
/// ```
@experimental
final class FeatureEffectWrapper<State, Msg, Effect, E extends Effect>
    extends ProxyFeature<State, Msg, Effect> {
  /// The [EffectHandler] responsible for processing effects of type [E].
  final EffectHandler<E, Msg> handler;

  StreamSubscription? _subscription;

  /// Creates a new [FeatureEffectWrapper].
  ///
  /// - [feature]: The feature being wrapped.
  /// - [handler]: The effect handler for effects of type [E].
  ///
  /// It's much easier to use [wrapEffects], to not write all generic types.
  FeatureEffectWrapper({
    required super.feature,
    required this.handler,
  });

  /// Initializes the wrapper by:
  /// - Setting up a subscription to listen for effects of type [E] on the [effects] stream.
  /// - Processing any [initialEffects] of type [E].
  @override
  FutureOr<void> init() {
    _subscription =
        effects.whereType<E>().listen((effect) => handler(effect, accept));

    for (final effect in initialEffects) {
      if (effect is E) {
        handler(effect, accept);
      }
    }

    return feature.init();
  }

  /// Disposes of resources managed by the wrapper.
  ///
  /// - Processes any [disposableEffects] of type [E].
  /// - Disposes the [handler] if it implements [Disposable].
  /// - Cancels the subscription to the effects stream.
  @override
  Future<void> dispose() async {
    for (final effect in disposableEffects) {
      if (effect is E) {
        await handler(effect, accept);
      }
    }

    if (handler is Disposable) {
      await (handler as Disposable).dispose();
    }

    await _subscription?.cancel();
    return feature.dispose();
  }
}

/// Extension for easily wrapping a feature with an [EffectHandler].
///
/// Provides a convenient method for adding an [EffectHandler] to handle specific
/// effect types without directly interacting with [FeatureEffectWrapper].
@experimental
extension EffectHandlerWrapperUtils<State, Msg, Effect>
    on Feature<State, Msg, Effect> {
  /// Wraps the feature with an [EffectHandler] for effects of type [E].
  ///
  /// This creates a [FeatureEffectWrapper] that delegates to the current feature
  /// while adding custom handling for effects of type [E].
  ///
  /// - [handler]: The handler for processing effects of type [E].
  ///
  /// ### Example:
  /// ```dart
  /// final wrappedFeature = myFeature.wrap<LogEffect>(
  ///   (effect, emit) => print('Log effect: $effect'),
  /// );
  /// ```
  Feature<State, Msg, Effect> wrapEffects<E extends Effect>(
    EffectHandler<E, Msg> handler,
  ) =>
      FeatureEffectWrapper(
        feature: this,
        handler: handler,
      );
}
