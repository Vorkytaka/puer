import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:puer/puer.dart';

import 'feature_listener.dart';
import 'feature_provider.dart';

/// Signature for the `builder` function which takes the `BuildContext` and
/// [state] and is responsible for returning a widget which is to be rendered.
@experimental
typedef FeatureWidgetBuilder<S> = Widget Function(
  BuildContext context,
  S state,
);

/// A widget that rebuilds its child when the state of a [Feature] changes.
///
/// [FeatureBuilder] listens to the state stream of a [Feature] and rebuilds
/// its child widget using a provided [builder] whenever the state changes.
///
/// ### Features:
/// - Listens for state changes in the associated [Feature].
/// - Optionally filters rebuilds using a [buildWhen] condition.
/// - Supports injection of a specific [Feature] instance or resolves it from the widget tree.
///
/// ### Usage:
///
/// ```dart
/// FeatureBuilder<MyFeature, MyState, MyMessage, MyEffect>(
///   builder: (context, state) {
///     return Text('Current state: ${state.value}');
///   },
/// );
/// ```
@experimental
class FeatureBuilder<F extends Feature<S, dynamic, dynamic>, S>
    extends StatefulWidget {
  final FeatureWidgetBuilder<S> builder;
  final F? feature;
  final FeatureStateCondition<S>? buildWhen;

  const FeatureBuilder({
    required this.builder,
    this.feature,
    this.buildWhen,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _FeatureBuilderState<F, S>();
  }
}

class _FeatureBuilderState<F extends Feature<S, dynamic, dynamic>, S>
    extends State<FeatureBuilder<F, S>> {
  late F _feature;
  late S _state;

  @override
  void initState() {
    super.initState();

    _feature = widget.feature ?? FeatureProvider.of<F>(context);
    _state = _feature.state;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final feature = widget.feature ?? FeatureProvider.of<F>(context);
    if (_feature != feature) {
      _feature = feature;
      _state = _feature.state;
    }
  }

  @override
  void didUpdateWidget(covariant FeatureBuilder<F, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFeature = oldWidget.feature ?? FeatureProvider.of<F>(context);
    final feature = widget.feature ?? oldFeature;
    if (oldFeature != feature) {
      _feature = feature;
      _state = _feature.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureListener<F, S>(
      listener: (context, state) => setState(() => _state = state),
      listenWhen: widget.buildWhen,
      child: widget.builder(context, _state),
    );
  }
}
