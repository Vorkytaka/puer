import 'transition.dart';

abstract interface class ReadOnlyFeature<State, Message, Effect> {
  /// Initial effects executed when the feature is created.
  ///
  /// Each effect handlers of this feature will get all of this effects on initialization.
  Iterable<Effect> get initialEffects;

  /// Effects executed when the feature is disposed.
  ///
  /// Each effect handlers of this feature will get all of this effects on disposal.
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
  /// Each time a message is processed, a [Transition] is emitted containing:
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

/// A type-safe wrapper that prevents mutation of a feature.
///
/// This wrapper implements the [ReadOnlyFeature] interface and delegates all
/// read-only operations to the underlying feature, while preventing access to
/// mutating methods like `accept`, `init`, and `dispose`.
///
/// ### Purpose
///
/// Use this wrapper when you need to share a feature across component boundaries
/// without allowing consumers to modify its state. This enforces architectural
/// boundaries and prevents unintended side effects.
///
/// ### Example
///
/// ```dart
/// // In a parent component
/// final feature = Feature<int, String, String>(
///   initialState: 0,
///   update: (state, msg) => (state + 1, []),
/// );
///
/// // Share read-only access with a child component
/// final readOnlyFeature = ReadOnlyFeatureWrapper(feature: feature);
/// childComponent.setFeature(readOnlyFeature);
///
/// // Child can read state but cannot call add/init/dispose
/// print(readOnlyFeature.state); // ✅ Works
/// // readOnlyFeature.add('msg'); // ❌ Compile error - method not available
/// ```
///
/// ### Pattern
///
/// This implements the wrapper/proxy pattern to provide a restricted interface
/// to the underlying feature. The `final` class modifier prevents subclassing
/// to maintain type safety guarantees.
///
/// See also:
/// - [ReadOnlyFeature] for the read-only interface definition
/// - [ReadOnlyFeatureWrapperExt] for the convenient `.asReadOnly` extension
final class ReadOnlyFeatureWrapper<State, Message, Effect>
    implements ReadOnlyFeature<State, Message, Effect> {
  final ReadOnlyFeature<State, Message, Effect> _feature;

  /// Creates a read-only wrapper around the given [feature].
  ///
  /// The wrapper delegates all read-only operations to [feature] while
  /// preventing access to mutating methods.
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

/// Extension providing a convenient way to create a read-only view of a feature.
///
/// This extension adds the [asReadOnly] getter to any [ReadOnlyFeature],
/// which wraps it in a [ReadOnlyFeatureWrapper] to prevent mutation.
///
/// ### Example
///
/// ```dart
/// final feature = Feature<int, String, String>(
///   initialState: 0,
///   update: (state, msg) => (state + 1, []),
/// );
///
/// // Create a read-only view
/// final readOnly = feature.asReadOnly;
///
/// // Can access state
/// print(readOnly.state); // ✅ Works
///
/// // Cannot mutate
/// // readOnly.add('msg'); // ❌ Compile error
/// ```
///
/// ### Use Cases
///
/// - Passing features to child components that should only observe state
/// - Sharing features across architectural boundaries
/// - Preventing accidental mutations in read-only contexts
/// - Creating immutable views for testing or logging
extension ReadOnlyFeatureWrapperExt<State, Message, Effect>
    on ReadOnlyFeature<State, Message, Effect> {
  /// Returns a read-only wrapper of this feature.
  ///
  /// The returned wrapper delegates all read-only operations to this feature
  /// while preventing access to mutating methods like `accept`, `init`, and `dispose`.
  ReadOnlyFeature<State, Message, Effect> get asReadOnly =>
      ReadOnlyFeatureWrapper(feature: this);
}
