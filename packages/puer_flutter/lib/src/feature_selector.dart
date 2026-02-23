import 'package:flutter/widgets.dart';
import 'package:puer/feature.dart';

import '../puer_flutter.dart';

/// Function representing a selector function to extract a value from the state.
typedef FeatureWidgetSelector<S, T> = T Function(S state);

/// A widget that selects a value from the state of a [Feature] and rebuilds.
///
/// [FeatureSelector] listens to the state stream of a [Feature] and rebuilds
/// its child widget using a provided [builder] whenever the selected value changes.
///
/// ### Features:
/// - Listens for state changes in the associated [Feature].
/// - Optionally filters rebuilds using a [selector] function.
/// - Supports injection of a specific [Feature] instance or resolves it from the widget tree.
///
/// ### Usage:
///
/// ```dart
/// FeatureSelector<MyFeature, MyState, int>(
///   selector: (state) => state.value,
///   builder: (context, value) {
///     return Text('Current value: $value');
///   },
/// );
/// ```
final class FeatureSelector<F extends Feature<S, dynamic, dynamic>, S, T>
    extends StatefulWidget {
  /// A function to extract a value from the state.
  final FeatureWidgetSelector<S, T> selector;

  /// A function that builds a widget based on the selected value.
  final FeatureWidgetBuilder<T> builder;

  /// The [Feature] instance to be listened to.
  /// If null, it is resolved from the widget tree.
  final F? feature;

  /// Creates a [FeatureSelector] widget.
  ///
  /// - [selector]: A function to extract a value from the state.
  /// - [builder]: A function that builds a widget based on the selected value.
  /// - [feature]: The [Feature] instance to be listened to.
  const FeatureSelector({
    required this.selector,
    required this.builder,
    this.feature,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FeatureSelectorState<F, S, T>();
}

final class _FeatureSelectorState<F extends Feature<S, dynamic, dynamic>, S, T>
    extends State<FeatureSelector<F, S, T>> {
  late F _feature;
  late T _value;

  @override
  void initState() {
    super.initState();

    _feature = widget.feature ?? FeatureProvider.of<F>(context);
    _value = widget.selector(_feature.state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final feature = widget.feature ?? FeatureProvider.of<F>(context);
    if (feature != _feature) {
      _feature = feature;
      _value = widget.selector(_feature.state);
    }
  }

  @override
  void didUpdateWidget(covariant FeatureSelector<F, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFeature = oldWidget.feature ?? FeatureProvider.of<F>(context);
    final feature = widget.feature ?? oldFeature;

    if (feature != oldFeature) {
      _feature = feature;
      _value = widget.selector(_feature.state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureListener<F, S>(
      listener: _onListen,
      child: widget.builder(context, _value),
    );
  }

  void _onListen(BuildContext context, S state) {
    final value = widget.selector(state);
    if (value != _value) {
      setState(() => _value = value);
    }
  }
}
