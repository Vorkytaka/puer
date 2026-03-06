import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:puer/puer.dart';

/// A callback that is invoked whenever the state of the associated [Feature] changes.
///
/// - [context]: The [BuildContext] of the widget.
/// - [state]: The new state of the [Feature].
@experimental
typedef FeatureWidgetListener<S> = void Function(BuildContext context, S state);

/// A condition that determines whether to notify the [FeatureWidgetListener]
/// based on the previous and current states.
///
/// Returns `true` if the listener should be invoked, otherwise `false`.
@experimental
typedef FeatureStateCondition<S> = bool Function(S previous, S current);

/// A widget that listens to state changes in a [Feature] and invokes a callback.
///
/// The [FeatureListener] subscribes to the state stream of a [Feature] and
/// triggers a [FeatureWidgetListener] whenever the state changes. You can optionally
/// specify a condition using [listenWhen] to control when the listener is invoked.
///
/// ### Key Features:
/// - Automatically handles subscription and unsubscription to the [Feature]'s state stream.
/// - Allows filtering of state change notifications using [listenWhen].
/// - Supports direct injection of a [Feature] instance or resolves it from the widget tree.
///
/// ### Usage:
///
/// ```dart
/// FeatureListener<MyFeature, MyState, MyMessage, MyEffect>(
///   listener: (context, state) {
///     // Respond to state changes
///   },
///   child: MyWidget(),
/// );
/// ```
@experimental
class FeatureListener<F extends Feature<S, dynamic, dynamic>, S>
    extends StatefulWidget {
  /// The callback to be invoked when the state changes.
  final FeatureWidgetListener<S> listener;

  /// The child widget to be rendered.
  final Widget child;

  /// The [Feature] instance to be listened to.
  /// If null, it is resolved from the widget tree.
  final F? feature;

  /// A condition that determines whether the [listener] should be invoked
  /// based on the previous and current states.
  ///
  /// If null, the listener is invoked on every state change.
  final FeatureStateCondition<S>? listenWhen;

  /// Creates a [FeatureListener] widget.
  ///
  /// - [listener]: A callback to handle state changes.
  /// - [child]: The widget subtree that depends on the [Feature].
  /// - [feature]: An optional [Feature] instance to listen to. If null,
  ///   the [Feature] is resolved from the widget tree.
  /// - [listenWhen]: An optional condition to filter state change notifications.
  const FeatureListener({
    required this.listener,
    required this.child,
    this.feature,
    this.listenWhen,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FeatureListenerState<F, S>();
}

class _FeatureListenerState<F extends Feature<S, dynamic, dynamic>, S>
    extends State<FeatureListener<F, S>> {
  late F _feature;
  late S _previousState;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _feature = widget.feature ?? context.read<F>();
    _previousState = _feature.state;
    _subscribe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feature = widget.feature ?? context.read<F>();
    if (_feature != feature) {
      if (_subscription != null) {
        _unsubscribe();
        _feature = feature;
        _previousState = _feature.state;
      }
      _subscribe();
    }
  }

  @override
  void didUpdateWidget(covariant FeatureListener<F, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFeature = oldWidget.feature ?? context.read<F>();
    final feature = widget.feature ?? oldFeature;
    if (feature != oldFeature) {
      if (_subscription != null) {
        _unsubscribe();
        _feature = feature;
        _previousState = _feature.state;
      }
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _subscribe() {
    _subscription = _feature.stateStream.listen((state) {
      if (mounted &&
          state != _previousState &&
          (widget.listenWhen?.call(_previousState, state) ?? true)) {
        widget.listener(context, state);
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
