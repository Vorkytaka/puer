import 'dart:async';

import 'package:meta/meta.dart';

import '../../../feature.dart';

base class FeatureBase<State, Msg, Effect>
    implements Feature<State, Msg, Effect> {
  @protected
  final Update<State, Msg, Effect> update;

  @protected
  final List<EffectHandler<Effect, Msg>> effectHandlers;

  @protected
  final StateStream<State> stateSubject;

  @protected
  final effectsController = StreamController<Effect>.broadcast();

  @override
  final List<Effect> initialEffects;

  @override
  final List<Effect> disposableEffects;

  FeatureBase({
    required State initialState,
    required this.update,
    required List<EffectHandler<Effect, Msg>> effectHandlers,
    List<Effect> initialEffects = const [],
    List<Effect> disposableEffects = const [],
  })  : stateSubject = StateStream.seeded(initialState),
        effectHandlers = List.unmodifiable(effectHandlers),
        initialEffects = List.unmodifiable(initialEffects),
        disposableEffects = List.unmodifiable(disposableEffects);

  StreamSubscription? _effectSubscription;

  @override
  Stream<State> get stateStream => stateSubject.stream;

  @override
  State get state => stateSubject.value;

  @override
  Stream<Effect> get effects => effectsController.stream;

  @override
  void accept(Msg message) {
    final (newState, effects) = update(stateSubject.value, message);
    if (newState != null && stateSubject.value != newState) {
      stateSubject.add(newState);
    }
    if (effects.isNotEmpty) {
      effects.forEach(effectsController.add);
    }
  }

  @override
  void init() {
    for (final effect in initialEffects) {
      _handleEffect(effect);
    }

    _listenForEffects();
  }

  @override
  Future<void> dispose() async {
    for (final effect in disposableEffects) {
      _handleEffect(effect);
    }

    await Future.wait(
      effectHandlers
          .whereType<Disposable>()
          .map((disposable) => disposable.dispose()),
    );

    await _effectSubscription?.cancel();
    await stateSubject.close();
    await effectsController.close();
  }

  void _listenForEffects() {
    _effectSubscription = effects.listen(_handleEffect);
  }

  /// Send [effect] to each effect handler in this feature.
  ///
  /// This will not send effect to the handlers that was added as wrapper
  void _handleEffect(Effect effect) {
    for (final handler in effectHandlers) {
      handler(effect, accept);
    }
  }
}
