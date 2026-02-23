import 'dart:async';

import 'package:meta/meta.dart';

import 'disposable.dart';
import 'effect_handler.dart';
import 'feature.dart';
import 'state_stream.dart';
import 'transition.dart';
import 'update.dart';

base class FeatureBase<State, Msg, Effect>
    implements Feature<State, Msg, Effect> {
  @protected
  final Update<State, Msg, Effect> update;

  @protected
  final List<EffectHandler<Effect, Msg>> effectHandlers;

  final StateStream<State> _stateSubject;

  final _effectsController = StreamController<Effect>.broadcast();
  final _transitionController =
      StreamController<Transition<State, Msg, Effect>>.broadcast();

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
  })  : _stateSubject = StateStream.seeded(initialState),
        effectHandlers = List.unmodifiable(effectHandlers),
        initialEffects = List.unmodifiable(initialEffects),
        disposableEffects = List.unmodifiable(disposableEffects);

  StreamSubscription? _effectSubscription;
  bool _isDisposed = false;

  @override
  Stream<State> get stateStream => _stateSubject.stream;

  @override
  State get state => _stateSubject.value;

  @override
  Stream<Effect> get effects => _effectsController.stream;

  /// Protected method to emit a new state.
  ///
  /// This should be used by subclasses instead of directly accessing the state stream.
  @protected
  void emitState(State state) {
    if (_isDisposed) {
      throw StateError('Cannot emit state after FeatureBase is disposed.');
    }
    _stateSubject.add(state);
  }

  /// Protected method to emit an effect.
  ///
  /// This should be used by subclasses instead of directly accessing the effects controller.
  @protected
  void emitEffect(Effect effect) {
    if (_isDisposed) {
      throw StateError('Cannot emit effect after FeatureBase is disposed.');
    }
    if (!_effectsController.isClosed) {
      _effectsController.add(effect);
    }
  }

  /// Protected method to emit a transition.
  ///
  /// This should be used by subclasses instead of directly accessing the transition controller.
  @protected
  void emitTransition({
    required State oldState,
    required Msg message,
    required State? newState,
    required List<Effect> effects,
  }) {
    if (_isDisposed) {
      throw StateError('Cannot emit transition after FeatureBase is disposed.');
    }
    if (!_transitionController.isClosed) {
      _transitionController.add(
        (
          stateBefore: oldState,
          message: message,
          stateAfter: newState,
          effects: effects,
        ),
      );
    }
  }

  @override
  void accept(Msg message) {
    if (_isDisposed) {
      throw StateError('Cannot accept message after FeatureBase is disposed.');
    }

    final oldState = state;
    final (newState, effects) = update(_stateSubject.value, message);
    if (newState != null && _stateSubject.value != newState) {
      emitState(newState);
    }
    emitTransition(
      oldState: oldState,
      message: message,
      newState: newState,
      effects: effects,
    );
    if (effects.isNotEmpty) {
      effects.forEach(emitEffect);
    }
  }

  @override
  Stream<Transition<State, Msg, Effect>> get transitions =>
      _transitionController.stream;

  @override
  void init() {
    assert(_effectSubscription == null, 'init() called multiple times');

    for (final effect in initialEffects) {
      _handleEffect(effect);
    }

    _listenForEffects();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    // Cancel subscription first to prevent race conditions
    await _effectSubscription?.cancel();

    for (final effect in disposableEffects) {
      _handleEffect(effect);
    }

    await Future.wait(
      effectHandlers
          .whereType<Disposable>()
          .map((disposable) => disposable.dispose()),
    );

    await _stateSubject.close();
    await _effectsController.close();
    await _transitionController.close();
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
