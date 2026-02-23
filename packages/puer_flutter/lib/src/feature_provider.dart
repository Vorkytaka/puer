import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:puer/puer.dart';

/// A typedef representing a factory function to create a [Feature] instance.
///
/// This is typically used to lazily or eagerly instantiate a [Feature]
/// within a [FeatureProvider].
///
/// - [F]: The type of the [Feature].
@experimental
typedef CreateFeature<F extends Feature> = F Function(BuildContext context);

/// A provider widget for managing and exposing a [Feature] to the widget tree.
///
/// [FeatureProvider] allows you to create or provide an existing [Feature] instance
/// and makes it available to its descendants in the widget tree using the [FeatureProvider.of] method.
///
/// ### Usage
///
/// There are two ways to use [FeatureProvider]:
/// 1. **Create Mode**: Instantiate a [Feature] dynamically:
///    ```dart
///    FeatureProvider.create(
///      create: (context) => MyFeature(...),
///      child: MyWidget(),
///    );
///    ```
///
/// 2. **Value Mode**: Provide an existing [Feature] instance:
///    ```dart
///    FeatureProvider.value(
///      value: myFeatureInstance,
///      child: MyWidget(),
///    );
///    ```
///
/// ### Key Parameters
/// - [F]: The type of the [Feature].
@experimental
class FeatureProvider<F extends Feature> extends StatelessWidget {
  /// An existing [Feature] instance to be provided.
  final F? _value;

  /// A factory function to create a new [Feature] instance.
  final CreateFeature<F>? _create;

  /// The widget subtree that will have access to the [Feature].
  final Widget child;

  /// If `true`, the [Feature] will only be instantiated when first accessed.
  /// Defaults to `false`.
  final bool lazy;

  /// Creates a [FeatureProvider] using a factory function.
  ///
  /// - [create]: A function to create the [Feature].
  /// - [child]: The widget subtree that will have access to the [Feature].
  /// - [lazy]: If `true`, delays creation until first accessed.
  const FeatureProvider.create({
    required CreateFeature<F> create,
    required this.child,
    this.lazy = false,
    super.key,
  })  : _value = null,
        _create = create;

  /// Creates a [FeatureProvider] with an existing [Feature] instance.
  ///
  /// - [value]: The [Feature] instance to be provided.
  /// - [child]: The widget subtree that will have access to the [Feature].
  /// - [lazy]: If `true`, delays any associated actions until first accessed.
  const FeatureProvider.value({
    required F value,
    required this.child,
    this.lazy = false,
    super.key,
  })  : _value = value,
        _create = null;

  @override
  Widget build(BuildContext context) {
    assert(
      (_value != null && _create == null) ||
          (_value == null && _create != null),
      'Either `value` or `create` must be provided, but not both.',
    );

    final value = _value;
    return value != null
        ? InheritedProvider<F>.value(
            value: value,
            startListening: _startListening,
            lazy: lazy,
            child: child,
          )
        : InheritedProvider<F>(
            create: _createAndInit,
            startListening: _startListening,
            dispose: (_, feature) => feature.dispose(),
            lazy: lazy,
            child: child,
          );
  }

  /// Retrieves the nearest [Feature] of type [F] from the widget tree.
  ///
  /// - [context]: The [BuildContext] used to locate the [Feature].
  /// - [listen]: Whether to listen for changes in the [Feature]. Defaults to `false`.
  ///
  /// Throws a [FlutterError] if no [Feature] of the required type is found.
  static F of<F extends Feature>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<F>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != F) {
        rethrow;
      }
      throw FlutterError(
        '''
        FeatureProvider.of() called with a context that does not contain a $F.
        Ensure that a FeatureProvider<$F> is an ancestor of the context.

        Context used: $context
        ''',
      );
    }
  }

  /// Internal method to start listening to state changes in the [Feature].
  ///
  /// This triggers a rebuild of dependent widgets whenever the state changes.
  VoidCallback _startListening(InheritedContext<F?> element, F value) {
    return value.stateStream
        .listen((_) => element.markNeedsNotifyDependents())
        .cancel;
  }

  F _createAndInit(BuildContext context) {
    assert(_create != null);

    final instance = _create!.call(context);
    instance.init();
    return instance;
  }
}
