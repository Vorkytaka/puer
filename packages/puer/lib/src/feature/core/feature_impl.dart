part of 'feature.dart';

@experimental
final class _FeatureImpl<State, Msg, Effect>
    implements Feature<State, Msg, Effect> {
  final Update<State, Msg, Effect> _update;
  final List<EffectHandler<Effect, Msg>> _effectHandlers;

  @override
  final List<Effect> initialEffects;

  @override
  final List<Effect> disposableEffects;

  _FeatureImpl({
    required State initialState,
    required Update<State, Msg, Effect> update,
    required List<EffectHandler<Effect, Msg>> effectHandlers,
    List<Effect> initialEffects = const [],
    List<Effect> disposableEffects = const [],
  })  : _stateSubject = BehaviorSubject.seeded(initialState),
        _update = update,
        _effectHandlers = List.unmodifiable(effectHandlers),
        initialEffects = List.unmodifiable(initialEffects),
        disposableEffects = List.unmodifiable(disposableEffects);

  final BehaviorSubject<State> _stateSubject;
  final _effectsController = StreamController<Effect>.broadcast();
  StreamSubscription? _effectSubscription;

  @override
  Stream<State> get stateStream => _stateSubject.stream;

  @override
  State get state => _stateSubject.value;

  @override
  Stream<Effect> get effects => _effectsController.stream;

  @override
  void accept(Msg message) {
    final (newState, effects) = _update(_stateSubject.value, message);
    if (newState != null && _stateSubject.value != newState) {
      _stateSubject.add(newState);
    }
    if (effects.isNotEmpty) {
      effects.forEach(_effectsController.add);
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

    await Future.wait(_effectHandlers
        .whereType<Disposable>()
        .map((disposable) => disposable.dispose()));

    await _effectSubscription?.cancel();
    await _stateSubject.close();
    await _effectsController.close();
  }

  void _listenForEffects() {
    _effectSubscription = effects.listen(_handleEffect);
  }

  /// Send [effect] to each effect handler in this feature.
  ///
  /// This will not send effect to the handlers that was added as wrapper
  void _handleEffect(Effect effect) {
    for (final handler in _effectHandlers) {
      handler(effect, accept);
    }
  }
}
