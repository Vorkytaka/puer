import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'disposable.dart';
part 'effect_handler.dart';
part 'feature_impl.dart';
part 'update.dart';

/// Core interface for building features.
///
/// Inspired by The Elm Architecture.
///
/// This interface encapsulates the primary elements of a feature:
/// - [State]: Represents the feature's current state.
/// - [Msg]: Defines messages or events that may alter the state.
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
@experimental
abstract interface class Feature<State, Msg, Effect> implements Disposable {
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
    required Update<State, Msg, Effect> update,
    List<EffectHandler<Effect, Msg>> effectHandlers = const [],
    List<Effect> initialEffects = const [],
    List<Effect> disposableEffects = const [],
  }) =>
      _FeatureImpl(
        initialState: initialState,
        update: update,
        effectHandlers: effectHandlers,
        initialEffects: initialEffects,
        disposableEffects: disposableEffects,
      );

  /// Initial effects executed when the feature is created.
  ///
  /// Each effect handlers of this feature will get all of this effects on [init].
  List<Effect> get initialEffects;

  /// Effects executed when the feature is disposed.
  ///
  /// Each effect handlers of this feature will get all of this effects on [dispose].
  List<Effect> get disposableEffects;

  /// A stream providing updates to the feature's state.
  ///
  /// Listen to this stream to react to state changes, such as updating the UI.
  Stream<State> get stateStream;

  /// The current state of the feature.
  ///
  /// Access this property to retrieve a snapshot of the current state.
  /// We all love streams, but this is sync call. :)
  State get state;

  /// A stream of side effects triggered by the feature.
  ///
  /// Side effects include tasks like API calls or data storage, which don't modify the state directly.
  /// This also can be used as place to send some one-time UI events.
  Stream<Effect> get effects;

  /// Processes an incoming message.
  ///
  /// Invoked to handle messages that may trigger state updates or effects.
  /// This method will use Update function to handle changes and send result forward.
  void accept(Msg message);

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
