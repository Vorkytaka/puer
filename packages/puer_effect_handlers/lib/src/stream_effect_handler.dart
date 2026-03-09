import 'dart:async';

import 'package:puer/puer.dart';

typedef ValueToMessage<T, Message> = Message Function(T value);
typedef EffectCondition<Effect> = bool Function(Effect effect);

extension StreamEffectHandlerExt<T> on Stream<T> {
  EffectHandler<Effect, Message> toEffectHandler<Effect, Message>({
    required ValueToMessage<T, Message> mapper,
    required EffectCondition<Effect> isStartEffect,
    required EffectCondition<Effect> isEndEffect,
  }) =>
      StreamEffectHandler(
        stream: this,
        mapper: mapper,
        isStartEffect: isStartEffect,
        isEndEffect: isEndEffect,
      );
}

final class StreamEffectHandler<Effect, Message, T>
    implements EffectHandler<Effect, Message>, Disposable {
  final Stream<T> _stream;
  final ValueToMessage<T, Message> mapper;
  final EffectCondition<Effect> isStartEffect;
  final EffectCondition<Effect> isEndEffect;

  StreamSubscription<Message>? _subscription;

  StreamEffectHandler({
    required Stream<T> stream,
    required this.mapper,
    required this.isStartEffect,
    required this.isEndEffect,
  }) : _stream = stream;

  @override
  FutureOr<void> call(
    Effect effect,
    MsgEmitter<Message> emit,
  ) async {
    if (_subscription == null && isStartEffect(effect)) {
      _subscription = _stream.map(mapper).listen(emit);
    } else if (_subscription != null && isEndEffect(effect)) {
      await dispose();
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
