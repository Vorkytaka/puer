import 'dart:async';

import 'disposable.dart';
import 'effect_handler.dart';
import 'feature_base.dart';
import 'read_only_feature.dart';
import 'update.dart';

/// Core interface for building features.
///
/// Inspired by The Elm Architecture.
///
/// This interface encapsulates the primary elements of a feature:
/// - [State]: Represents the feature's current state.
/// - [Message]: Defines messages or events that may alter the state.
/// - [Effect]: Represents side effects triggered by messages but do not modify state directly.
///
/// Due to its generic nature, this interface may appear complex. To simplify usage,
/// consider defining type aliases and factory functions for specific features:
/// ```dart
/// typedef JsonFeature = Feature<JsonState, JsonMsg, JsonEffect>;
///
/// JsonFeature jsonFeatureFactory() => JsonFeature(
///       initialState: const JsonState.init(),
///       update: _jsonUpdate,
///       effectHandlers: [_jsonEffectHandler],
///       initialEffects: const [],
///     );
/// ```
abstract interface class Feature<State, Message, Effect>
    implements ReadOnlyFeature<State, Message, Effect>, Disposable {
  /// Creates a new `Feature` instance.
  ///
  /// - [initialState]: The initial state of the feature, defining its starting condition.
  /// - [update]: A pure function handling state transitions based on
  ///   incoming messages and effects. You can know it as a Reducer.
  /// - [effectHandlers]: A list of handlers for processing side effects. Each
  ///   handler can generate new messages based on the effects. This handlers will handle each effects, without exceptions.
  /// - [initialEffects]: Optional list of effects to execute when the feature is initialized.
  /// - [disposableEffects]: Optional list of effects to manage resources during the feature's lifecycle.
  factory Feature({
    required State initialState,
    required Update<State, Message, Effect> update,
    Iterable<EffectHandler<Effect, Message>> effectHandlers = const [],
    Iterable<Effect> initialEffects = const [],
    Iterable<Effect> disposableEffects = const [],
  }) =>
      FeatureBase(
        initialState: initialState,
        update: update,
        effectHandlers: effectHandlers,
        initialEffects: initialEffects,
        disposableEffects: disposableEffects,
      );

  /// Processes an incoming message.
  ///
  /// Invoked to handle messages that may trigger state updates or effects.
  /// This method will use Update function to handle changes and send result forward.
  void add(Message message);

  /// Initializes the feature and prepares it for usage.
  ///
  /// This method __must__ be called before we start to use this feature.
  ///
  /// Performs setup tasks, such as allocating resources or establishing connections.
  /// May complete synchronously or asynchronously.
  FutureOr<void> init();

  /// Cleans up resources when the feature is no longer needed.
  ///
  /// This method is called during the feature's disposal lifecycle and may perform
  /// asynchronous operations.
  @override
  Future<void> dispose();
}
