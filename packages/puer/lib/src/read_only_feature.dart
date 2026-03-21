import 'transition.dart';

abstract interface class ReadOnlyFeature<State, Message, Effect> {
  /// Initial effects executed when the feature is created.
  ///
  /// Each effect handlers of this feature will get all of this effects on [init].
  Iterable<Effect> get initialEffects;

  /// Effects executed when the feature is disposed.
  ///
  /// Each effect handlers of this feature will get all of this effects on [dispose].
  Iterable<Effect> get disposableEffects;

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

  /// A stream of transitions representing each state change step in the feature.
  ///
  /// Each time a message is processed via [accept], a [Transition] is emitted containing:
  /// - The state before the message was processed
  /// - The message itself
  /// - The new state (or `null` if unchanged)
  /// - Any effects produced
  ///
  /// This stream is useful for:
  /// - Logging and debugging state changes
  /// - Time-travel debugging (tracking the complete history)
  /// - Analytics and monitoring
  /// - Testing and verification
  ///
  /// **Note:** Transitions are emitted **before** effects are sent to effect handlers.
  /// This means the transition contains the effects list, but the effects themselves
  /// may not have been processed yet.
  ///
  /// ### Example:
  /// ```dart
  /// feature.transitions.listen((transition) {
  ///   print('${transition.message} -> ${transition.stateAfter}');
  ///   if (transition.effects.isNotEmpty) {
  ///     print('Generated ${transition.effects.length} effects');
  ///   }
  /// });
  /// ```
  Stream<Transition<State, Message, Effect>> get transitions;
}

final class ReadOnlyFeatureWrapper<State, Message, Effect>
    implements ReadOnlyFeature<State, Message, Effect> {
  final ReadOnlyFeature<State, Message, Effect> _feature;

  const ReadOnlyFeatureWrapper({
    required ReadOnlyFeature<State, Message, Effect> feature,
  }) : _feature = feature;

  @override
  Iterable<Effect> get disposableEffects => _feature.disposableEffects;

  @override
  Stream<Effect> get effects => _feature.effects;

  @override
  Iterable<Effect> get initialEffects => _feature.initialEffects;

  @override
  State get state => _feature.state;

  @override
  Stream<State> get stateStream => _feature.stateStream;

  @override
  Stream<Transition<State, Message, Effect>> get transitions =>
      _feature.transitions;
}

extension ReadOnlyFeatureWrapperExt<State, Message, Effect>
    on ReadOnlyFeature<State, Message, Effect> {
  ReadOnlyFeature<State, Message, Effect> get asReadOnly =>
      ReadOnlyFeatureWrapper(feature: this);
}
