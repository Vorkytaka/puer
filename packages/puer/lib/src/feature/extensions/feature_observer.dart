import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import '../core/feature.dart';
import 'proxy_feature.dart';

/// A base class for observing feature lifecycle events and interactions.
///
/// [FeatureObserver] provides hooks to monitor a feature's lifecycle, state changes,
/// messages, and effects. This is useful for debugging, logging, or analytics.
///
/// ### Hooks:
/// - [onInit]: Called when the feature is initialized.
/// - [onDispose]: Called when the feature is disposed.
/// - [onState]: Called when the feature's state changes.
/// - [onMsg]: Called when a message is accepted by the feature.
/// - [onEffect]: Called when an effect is emitted by the feature.
///
/// ### Usage:
/// Extend this class and override the hooks you need. Attach the observer
/// using the observe extension.
///
/// Example:
/// ```dart
/// class MyObserver extends FeatureObserver<MyState, MyMsg, MyEffect> {
///   @override
///   void onState(MyState state) {
///     print('State changed: $state');
///   }
///
///   @override
///   void onMsg(MyMsg message) {
///     print('Message received: $message');
///   }
/// }
/// ```
@experimental
abstract class FeatureObserver<State, Msg, Effect> {
  /// Called when the feature is initialized.
  void onInit() {}

  /// Called when the feature is disposed.
  void onDispose() {}

  /// Called when the feature's state changes.
  ///
  /// - [state]: The new state.
  void onState(State state) {}

  /// Called when a message is accepted by the feature.
  ///
  /// - [message]: The message being processed.
  void onMsg(Msg message) {}

  /// Called when an effect is emitted by the feature.
  ///
  /// - [effect]: The effect emitted.
  void onEffect(Effect effect) {}
}

/// A function type for handling feature lifecycle events.
typedef OnInit = void Function();

/// A function type for handling feature disposal events.
typedef OnDispose = void Function();

/// A function type for handling state changes.
typedef OnState<State> = void Function(State state);

/// A function type for handling messages.
typedef OnMsg<Msg> = void Function(Msg message);

/// A function type for handling effects.
typedef OnEffect<Effect> = void Function(Effect effect);

/// A wrapper for adding observation capabilities to a [Feature].
///
/// [FeatureObserverWrapper] enhances a feature by integrating a [FeatureObserver],
/// allowing you to monitor lifecycle events, state changes, messages, and effects.
///
/// ### Key Features:
/// - Notifies the observer about lifecycle events (`onCreate`, `onInit`, `onDispose`).
/// - Observes and reports state updates, messages, and effects.
///
/// ### Example:
/// ```dart
/// final observedFeature = myFeature.observe(MyObserver());
/// ```
@experimental
final class FeatureObserverWrapper<State, Msg, Effect>
    extends ProxyFeature<State, Msg, Effect> {
  final OnInit? _onInit;
  final OnDispose? _onDispose;
  final OnState<State>? _onState;
  final OnMsg<Msg>? _onMsg;
  final OnEffect<Effect>? _onEffect;

  final _subscription = CompositeSubscription();

  /// Creates a new [FeatureObserverWrapper].
  ///
  /// - [feature]: The feature being observed.
  FeatureObserverWrapper({
    required super.feature,
    OnInit? onInit,
    OnDispose? onDispose,
    OnState<State>? onState,
    OnMsg<Msg>? onMsg,
    OnEffect<Effect>? onEffect,
  })  : _onEffect = onEffect,
        _onMsg = onMsg,
        _onState = onState,
        _onDispose = onDispose,
        _onInit = onInit;

  /// Notifies the observer when a message is accepted.
  @override
  void accept(Msg message) {
    _onMsg?.call(message);
    super.accept(message);
  }

  /// Initializes the feature and starts observing state and effect streams.
  @override
  FutureOr<void> init() {
    _onInit?.call();
    stateStream.listen(_onState).addTo(_subscription);
    effects.listen(_onEffect).addTo(_subscription);
    return super.init();
  }

  /// Disposes the feature and cleans up subscriptions.
  @override
  Future<void> dispose() {
    _onDispose?.call();
    _subscription.dispose();
    return super.dispose();
  }
}

/// Extension for attaching a [FeatureObserver] to a [Feature].
///
/// Provides a convenient method to wrap a feature with an observer.
///
/// ### Example:
/// ```dart
/// final observedFeature = myFeature.observe(MyObserver());
/// ```
@experimental
extension FeatureObserverWrapperHelper<S, M, E> on Feature<S, M, E> {
  /// Wraps the feature with a new [FeatureObserver].
  ///
  /// - [onInit]: Called when the feature is initialized.
  /// - [onDispose]: Called when the feature is disposed.
  /// - [onState]: Called when the feature's state changes.
  /// - [onMsg]: Called when a message is accepted by the feature.
  /// - [onEffect]: Called when an effect is emitted by the feature.
  ///
  /// Returns a [FeatureObserverWrapper] that monitors the feature's interactions.
  Feature<S, M, E> observe({
    OnInit? onInit,
    OnDispose? onDispose,
    OnState<S>? onState,
    OnMsg<M>? onMsg,
    OnEffect<E>? onEffect,
  }) =>
      FeatureObserverWrapper(
        feature: this,
        onInit: onInit,
        onDispose: onDispose,
        onState: onState,
        onMsg: onMsg,
        onEffect: onEffect,
      );

  /// Wraps the feature with the specified [observer].
  ///
  /// - [observer]: The observer to attach.
  ///
  /// Returns a [FeatureObserverWrapper] that monitors the feature's interactions.
  Feature<S, M, E> observeWith(FeatureObserver<S, M, E> observer) =>
      FeatureObserverWrapper(
        feature: this,
        onInit: observer.onInit,
        onDispose: observer.onDispose,
        onState: observer.onState,
        onMsg: observer.onMsg,
        onEffect: observer.onEffect,
      );
}
