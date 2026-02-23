import 'dart:async';

import 'package:meta/meta.dart';

import '../core/feature.dart';

/// A base class for creating proxy implementations of [Feature].
///
/// [ProxyFeature] acts as a wrapper around an existing [Feature] instance,
/// delegating all functionality to the wrapped feature. This is useful for
/// extending or modifying the behavior of a feature without changing its core
/// implementation.
///
/// ### Example Use Case:
/// - Logging: You could wrap a feature to log all messages and effects.
/// - Transformation: Apply additional processing to state or effects.
///
/// ### Key Points:
/// - Delegates all operations, such as state updates, message acceptance, and
///   effect handling, to the wrapped [feature].
/// - Can be extended to override specific behavior if needed.
@experimental
abstract base class ProxyFeature<State, Msg, Effect>
    implements Feature<State, Msg, Effect> {
  /// The wrapped [Feature] instance.
  final Feature<State, Msg, Effect> feature;

  /// Creates a [ProxyFeature] with the specified [feature].
  const ProxyFeature({required this.feature});

  /// Delegates to the [initialEffects] of the wrapped [feature].
  @override
  List<Effect> get initialEffects => feature.initialEffects;

  /// Delegates to the [disposableEffects] of the wrapped [feature].
  @override
  List<Effect> get disposableEffects => feature.disposableEffects;

  /// Delegates message handling to the wrapped [feature].
  @override
  void accept(Msg message) => feature.accept(message);

  /// Disposes the wrapped [feature].
  @override
  Future<void> dispose() => feature.dispose();

  /// Delegates effect stream access to the wrapped [feature].
  @override
  Stream<Effect> get effects => feature.effects;

  /// Initializes the wrapped [feature].
  @override
  FutureOr<void> init() => feature.init();

  /// Retrieves the current state from the wrapped [feature].
  @override
  State get state => feature.state;

  /// Delegates state stream access to the wrapped [feature].
  @override
  Stream<State> get stateStream => feature.stateStream;
}
