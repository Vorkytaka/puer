import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:puer/feature.dart';

import 'feature_listener.dart';

/// A widget that listens for specific effects emitted by a [Feature] and invokes a callback.
///
/// The [FeatureEffectListener] is useful for side-effect handling, such as showing notifications
/// or navigating based on emitted effects.
///
/// ### Features:
/// - Listens only to effects of type [Effect] emitted by the associated [Feature].
/// - Supports injection of a specific [Feature] instance or resolves it from the widget tree.
/// - Automatically manages subscription and unsubscription to the effect stream.
///
/// ### Usage:
///
/// ```dart
/// FeatureEffectListener<MyFeature, MyState, MyMessage, MyEffect, NavigateEffect>(
///   listener: (context, effect) {
///     // Handle specific effect
///     Navigator.of(context).pushNamed(effect.route);
///   },
///   child: MyWidget(),
/// );
/// ```
@experimental
class FeatureEffectListener<F extends Feature<dynamic, dynamic, E>, E,
    Effect extends E> extends StatefulWidget {
  /// A callback invoked when an effect of type [Effect] is emitted.
  final FeatureWidgetListener<Effect> listener;

  /// The [Feature] to listen to. If null, it will be resolved from the widget tree.
  final F? feature;

  /// The child widget to render.
  final Widget child;

  /// Creates a [FeatureEffectListener].
  ///
  /// - [listener]: A callback to handle specific effects.
  /// - [child]: The widget subtree to render.
  /// - [feature]: An optional [Feature] instance to listen to.
  const FeatureEffectListener({
    required this.listener,
    required this.child,
    this.feature,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _FeatureEffectListener<F, E, Effect>();
  }
}

class _FeatureEffectListener<F extends Feature<dynamic, dynamic, E>, E,
    Effect extends E> extends State<FeatureEffectListener<F, E, Effect>> {
  late F _feature;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _feature = widget.feature ?? context.read<F>();
    _subscribe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final feature = widget.feature ?? context.read<F>();
    if (feature != _feature) {
      _feature = feature;
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void didUpdateWidget(
    covariant FeatureEffectListener<F, E, Effect> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldFeature = oldWidget.feature ?? context.read<F>();
    final feature = widget.feature ?? context.read<F>();
    if (feature != oldFeature) {
      _feature = feature;
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _subscribe() {
    _subscription = _feature.effects
        .where((e) => e is Effect)
        .cast<Effect>()
        .listen((news) {
      if (mounted) {
        widget.listener(context, news);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
